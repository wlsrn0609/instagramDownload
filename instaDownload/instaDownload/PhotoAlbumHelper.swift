import Photos
import UIKit
import UniformTypeIdentifiers

extension PhotoAlbumHelper {
    fileprivate protocol Interface {
        
        func ensureAlbum(completion: @escaping (String?) -> Void)
        
        func saveImage(_ image: UIImage, toAlbumId albumId: String, format:PhotoAlbumHelper.SaveImageFormat, completion: @escaping (Bool) -> ())
        func saveImages(_ images:[UIImage], toAlbumId albumId: String, format:PhotoAlbumHelper.SaveImageFormat, completion: @escaping (Bool) -> ())
        
        //todo
        func saveVideo(fileURL: URL, toAlbumId albumId: String, completion: @escaping (Bool) -> Void)
    }
}

final class PhotoAlbumHelper {
    
    static let shared = PhotoAlbumHelper()
    private let albumTitle = "InstaDownload"
    private let albumIdKey = "instaDownload.album.localIdentifier"
    
    enum SaveImageFormat {
        case jpeg(quality: CGFloat) //0.0 ~ 1.0
        case png
    }
    
    //========================================================================================================================//
    
    public func saveImageToInstaDownload(_ image: UIImage, format:SaveImageFormat, completion: @escaping (Bool) -> Void) {
        self.requestAuthorization { [weak self] success in
            guard let self, success else {
                DispatchQueue.main.async { completion(false) }
                return }
            self.ensureAlbum { albumId in
                guard let albumId else {
                    DispatchQueue.main.async { completion(false) }
                    return }
                
                self.saveImage(image, toAlbumId: albumId, format: format) { success in
                    DispatchQueue.main.async {
                        completion(success)
                    }
                }
            }
        }
    }
    
    public func saveImagesToInstaDownload(_ images: [UIImage], format:SaveImageFormat, completion: @escaping (Bool) -> Void) {
        self.requestAuthorization { [weak self] success in
            guard let self, success else {
                DispatchQueue.main.async { completion(false) }
                return }
            self.ensureAlbum { albumId in
                guard let albumId else {
                    DispatchQueue.main.async { completion(false) }
                    return }
                
                self.saveImages(images, toAlbumId: albumId, format: format) { success in
                    DispatchQueue.main.async { completion(success) }
                }
            }
        }
    }
    
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:  // NOTE: addOnly 경로에서 limited가 내려오는 일은 거의 없지만, 호환성 대비 true 처리
            DispatchQueue.main.async { completion(true) }
        default:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newState in
                switch newState {
                case .authorized,.limited:
                    DispatchQueue.main.async { completion(true) }
                default:
                    DispatchQueue.main.async { completion(false) }
                }
            }
        }
    }
    
}

extension PhotoAlbumHelper : PhotoAlbumHelper.Interface {
    
    /// 앨범의 localIdentifier를 보장해서 completion으로 돌려줌
    fileprivate func ensureAlbum(completion: @escaping (String?) -> Void) {
        if let id = UserDefaults.standard.string(forKey: albumIdKey),
           let _ = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject {
            completion(id)
            return
        }

        // 제목으로 검색 (초기 1회만)
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        if let existing = (0..<fetch.count).compactMap({ fetch.object(at: $0) })
            .first(where: { $0.localizedTitle == albumTitle }) {
            let id = existing.localIdentifier
            UserDefaults.standard.set(id, forKey: albumIdKey)
            completion(id)
            return
        }

        // 없으면 생성
        var createdId: String?
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumTitle)
            let createdId = req.placeholderForCreatedAssetCollection.localIdentifier
        }, completionHandler: { success, _ in
            if success, let createdId, !createdId.isEmpty {
                UserDefaults.standard.set(createdId, forKey: self.albumIdKey)
                completion(createdId)
            }else{
                completion(nil)
            }
        })
    }
        
    fileprivate func saveImage(_ image: UIImage, toAlbumId albumId: String, format:SaveImageFormat, completion: @escaping (Bool) -> Void) {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject
        else { completion(false); return }

        let data : Data?
        let uti : String
        switch format {
        case .jpeg(let quality):
            data = image.jpegData(compressionQuality: quality)
            uti = UTType.jpeg.identifier
        case .png:
            data = image.pngData()
            uti = UTType.png.identifier
        }
        
        guard let data else {
            Logger.log("image data encode fail (format:\(format))")
            completion(false)
            return
        }
        
        let options = PHAssetResourceCreationOptions()
        options.uniformTypeIdentifier = uti
        options.originalFilename = {
            let ts = Int(Date().timeIntervalSince1970)
            switch format {
            case .jpeg: return "image_\(ts).jpg"
            case .png: return "image_\(ts).png"
            }
        }()
        
        PHPhotoLibrary.shared().performChanges({
            // 1) 에셋 생성
            let req = PHAssetCreationRequest.forAsset()
            req.addResource(with: .photo, data: data, options: options)
            
            if let changeRequest = PHAssetCollectionChangeRequest(for: album),
               let ph = req.placeholderForCreatedAsset {
                changeRequest.addAssets([ph] as NSArray)
            }
            
        }, completionHandler: { success, error in
            if let error {
                Logger.log("save image fail : \(error.localizedDescription)")
            }
            completion(success)
        })
    }
    
    fileprivate func saveImages(_ images:[UIImage], toAlbumId albumId: String, format:SaveImageFormat, completion: @escaping (Bool) -> ()) {
        var index = 0
        var allOK = true
        
        func step(){
            if index >= images.count {
                completion(allOK)
                return
            }
            let image = images[index]
            Logger.log("saveImage Index:\(index)/\(images.count)")
            
            saveImage(image, toAlbumId: albumId, format: format) { success in
                if !success { allOK = false }
                index += 1
                step()
            }
        }
        step()
    }
    
    //todo
    fileprivate func saveVideo(fileURL: URL, toAlbumId albumId: String, completion: @escaping (Bool) -> Void) {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject
        else { completion(false); return }

        PHPhotoLibrary.shared().performChanges({
            let create = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            guard let placeholder = create?.placeholderForCreatedAsset else { return }
            if let albumReq = PHAssetCollectionChangeRequest(for: album) {
                albumReq.addAssets([placeholder] as NSArray)
            }
        }, completionHandler: { success, _ in
            completion(success)
        })
    }
}
