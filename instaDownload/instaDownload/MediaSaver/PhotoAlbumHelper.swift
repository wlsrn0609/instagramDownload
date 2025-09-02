import Photos
import UIKit
import UniformTypeIdentifiers

public enum SaveImageFormat {
    case jpeg(quality: CGFloat) //0.0 ~ 1.0
    case png
    case heic(quality: CGFloat, fallbackToJPEG: Bool = true)
}


enum PhotoAlbumHelperError: Error {
    case notAuthorized
    case albumNotFound
    case albumCreationFailed
    case dataEncodingFailed
    case photosFrameworkError(String)
    case fileNotReachable               // ← 추가: 파일 접근 불가
    case unsupportedVideoType(String)   // ← 추가: 확장자/UTType 판별 실패
    case unknown
}

extension PhotoAlbumHelperError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "사진첩 접근 권한이 없습니다."
        case .albumNotFound:
            return "앨범을 찾을 수 없습니다."
        case .albumCreationFailed:
            return "앨범 생성에 실패했습니다."
        case .dataEncodingFailed:
            return "이미지 데이터를 인코딩할 수 없습니다."
        case .photosFrameworkError(let msg):
            return "Photos 프레임워크 오류: \(msg)"
        case .fileNotReachable:
            return "영상 파일에 접근할 수 없습니다."
        case .unsupportedVideoType(let ext):
            return "지원하지 않는 영상 형식입니다: \(ext)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

struct ImageDataInfo {
    let data : Data
    let uti : String
    let fileName : String
}

struct VideoInfo {
    let uti: String
    let fileName: String
}

extension PhotoAlbumHelper {
    fileprivate protocol Interface {
        
        func saveImageToInstaDownload(_ image: UIImage, format:SaveImageFormat, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void)
        func saveImagesToInstaDownload(_ images: [UIImage], format:SaveImageFormat, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void)

//        //todo
        func saveVideoToInstaDownload(_ fileURL: URL, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void)
        func saveVideosToInstaDownload(_ fileURLs: [URL], completion: @escaping (PhotoAlbumHelperVoidResult) -> Void)
    }
}

class PhotoAlbumHelper {
    
    static let shared = PhotoAlbumHelper()
    private let albumTitle = "InstaDownload"
    private let albumIdKey = "instaDownload.album.localIdentifier"
    
    typealias PhotoAlbumHelperVoidResult = Result<Void, Error>
    typealias PhotoAlbumHelperStringResult = Result<String, Error>
        
    @inline(__always)
    private func onMain(_ work: @escaping () -> ()) {
        Thread.isMainThread ? work() : DispatchQueue.main.async(execute: work)
    }
    
    public func saveImageToInstaDownload(_ image: UIImage, format:SaveImageFormat, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void) {
        
        self.requestAuthorization { [weak self] requestAuthorizationResult in
            guard let self else { return }
            
            switch requestAuthorizationResult {
            case .success:
                
                self.ensureAlbum { ensureAlbumResult in
                    
                    switch ensureAlbumResult {
                    case .success(let albumId):
                        
                        self.saveImage(image, toAlbumId: albumId, format: format) { saveImageResult in
                            self.onMain { completion(saveImageResult) }
                        }
                        
                    case .failure(let error):
                        self.onMain { completion(.failure(error)) }
                    }
                    
                }
                
            case .failure(let error):
                self.onMain { completion(.failure(error)) }
            }
        }
    }
    
    public func saveImagesToInstaDownload(_ images: [UIImage], format:SaveImageFormat, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void) {
        self.requestAuthorization { [weak self] requestAuthorizationResult in
            guard let self else { return }
            
            switch requestAuthorizationResult {
            case .success:
                
                self.ensureAlbum { ensureAlbumResult in
                    
                    switch ensureAlbumResult {
                    case .success(let albumId):
                        
                        self.saveImages(images, toAlbumId: albumId, format: format) { saveImagesResult in
                            self.onMain { completion(saveImagesResult) }
                        }
                        
                    case .failure(let error):
                        self.onMain { completion(.failure(error)) }
                    }
                    
                }
                
            case .failure(let error):
                self.onMain { completion(.failure(error)) }
            }
        }
    }
    
    public func requestAuthorization(completion: @escaping (PhotoAlbumHelperVoidResult) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:  // NOTE: addOnly 경로에서 limited가 내려오는 일은 거의 없지만, 호환성 대비 true 처리
            self.onMain { completion(.success(())) }
        default:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newState in
                switch newState {
                case .authorized,.limited:
                    self.onMain { completion(.success(())) }
                default:
                    self.onMain { completion(.failure(PhotoAlbumHelperError.notAuthorized)) }
                }
            }
        }
    }
    
    func saveVideoToInstaDownload(_ fileURL: URL, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void){
        self.requestAuthorization { [weak self] requestAuthorizationResult in
            guard let self else { return }
            
            switch requestAuthorizationResult {
            case .success:
                
                self.ensureAlbum { ensureAlbumResult in
                    
                    switch ensureAlbumResult {
                    case .success(let albumId):
                        
                        self.saveVideo(fileURL, toAlbumId: albumId) { saveVideoResult in
                            self.onMain { completion(saveVideoResult) }
                        }
                        
                    case .failure(let error):
                        self.onMain { completion(.failure(error)) }
                    }
                    
                }
                
            case .failure(let error):
                self.onMain { completion(.failure(error)) }
            }
        }
    }
    func saveVideosToInstaDownload(_ fileURLs: [URL], completion: @escaping (PhotoAlbumHelperVoidResult) -> Void){
        self.requestAuthorization { [weak self] requestAuthorizationResult in
            guard let self else { return }
            
            switch requestAuthorizationResult {
            case .success:
                
                self.ensureAlbum { ensureAlbumResult in
                    
                    switch ensureAlbumResult {
                    case .success(let albumId):
                        
                        self.saveVideos(fileURLs, toAlbumId: albumId) { saveVideoResult in
                            self.onMain { completion(saveVideoResult) }
                        }
                        
                    case .failure(let error):
                        self.onMain { completion(.failure(error)) }
                    }
                    
                }
                
            case .failure(let error):
                self.onMain { completion(.failure(error)) }
            }
        }
    }
}



extension PhotoAlbumHelper : PhotoAlbumHelper.Interface {
    
    /// 앨범의 localIdentifier를 보장해서 completion으로 돌려줌
    fileprivate func ensureAlbum(completion: @escaping (PhotoAlbumHelperStringResult) -> Void) {
        if let id = UserDefaults.standard.string(forKey: albumIdKey),
           let _ = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject {
            completion(.success(id))
            return
        }

        // 제목으로 검색 (초기 1회만)
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        if let existing = (0..<fetch.count).compactMap({ fetch.object(at: $0) })
            .first(where: { $0.localizedTitle == albumTitle }) {
            let id = existing.localIdentifier
            UserDefaults.standard.set(id, forKey: albumIdKey)
            completion(.success(id))
            return
        }

        // 없으면 생성
        var id: String?
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumTitle)
            id = req.placeholderForCreatedAssetCollection.localIdentifier
        }, completionHandler: { success, error in
            if success, let id, !id.isEmpty {
                UserDefaults.standard.set(id, forKey: self.albumIdKey)
                completion(.success(id))
            }else if let error {
                completion(.failure(PhotoAlbumHelperError.photosFrameworkError(error.localizedDescription)))
            }else{
                completion(.failure(PhotoAlbumHelperError.albumCreationFailed))
            }
        })
    }
        
    fileprivate func saveImage(_ image: UIImage, toAlbumId albumId: String, format:SaveImageFormat, completion: @escaping (PhotoAlbumHelperVoidResult) -> Void) {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject
        else { completion(.failure(PhotoAlbumHelperError.albumNotFound)); return }

        guard let imageDataInfo = makeImageDataInfo(image: image, format: format) else {
            completion(.failure(PhotoAlbumHelperError.dataEncodingFailed))
            return
        }
        
        let options = PHAssetResourceCreationOptions()
        options.uniformTypeIdentifier = imageDataInfo.uti
        options.originalFilename = imageDataInfo.fileName
        
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            req.addResource(with: .photo, data: imageDataInfo.data, options: options)
            
            if let changeRequest = PHAssetCollectionChangeRequest(for: album),
               let ph = req.placeholderForCreatedAsset {
                changeRequest.addAssets([ph] as NSArray)
            }
            
        }, completionHandler: { success, error in
            if success {
                completion(.success(()))
            } else if let error {
                completion(.failure(PhotoAlbumHelperError.photosFrameworkError(error.localizedDescription)))
            }else{
                completion(.failure(PhotoAlbumHelperError.unknown))
            }
        })
    }
    
    fileprivate func saveImages(_ images:[UIImage], toAlbumId albumId: String, format:SaveImageFormat, completion: @escaping (PhotoAlbumHelperVoidResult) -> ()) {
        
        var index = 0
        
        func step(){
            if index >= images.count {
                completion(.success(()))
                return
            }
            let image = images[index]
            Logger.log("saveImage Index:\(index)/\(images.count)")
            
            saveImage(image, toAlbumId: albumId, format: format) { result in
                switch result {
                case .success:
                    index += 1
                    step()
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        step()
    }
    
    /// URL의 확장자로 UTI/파일명을 결정. 확장 불명은 nil
    func makeVideoResourceOptions(for url: URL) -> VideoInfo? {
        let ts = Int(Date().timeIntervalSince1970)
        let ext = url.pathExtension.lowercased()
        
        // 대표적인 케이스 매핑
        switch ext {
        case "mp4":
            return VideoInfo(uti: UTType.mpeg4Movie.identifier,
                             fileName: url.lastPathComponent.isEmpty ? "VID_\(ts).mp4" : url.lastPathComponent)
        case "mov":
            return VideoInfo(uti: UTType.quickTimeMovie.identifier,
                             fileName: url.lastPathComponent.isEmpty ? "VID_\(ts).mov" : url.lastPathComponent)
        case "m4v":
            return VideoInfo(uti: "com.apple.m4v-video",   // UTType.m4v.identifier (iOS 17+)가 없으면 literal
                             fileName: url.lastPathComponent.isEmpty ? "VID_\(ts).m4v" : url.lastPathComponent)
        case "avi":
            return VideoInfo(uti: "public.avi",
                             fileName: url.lastPathComponent.isEmpty ? "VID_\(ts).avi" : url.lastPathComponent)
        default:
            // UTType로 유추 시도 (iOS 14+)
            if let ut = UTType(filenameExtension: ext)?.identifier {
                return VideoInfo(uti: ut,
                                 fileName: url.lastPathComponent.isEmpty ? "VID_\(ts).\(ext)" : url.lastPathComponent)
            }
            return nil
        }
    }
    
    // 단일 비디오 저장
    fileprivate func saveVideo(_ fileURL: URL,
                               toAlbumId albumId: String,
                               completion: @escaping (PhotoAlbumHelperVoidResult) -> Void) {
        
        // 앨범 확인
        guard let album = PHAssetCollection
            .fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject
        else { completion(.failure(PhotoAlbumHelperError.albumNotFound)); return }
        
        // 파일 접근 가능?
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            completion(.failure(PhotoAlbumHelperError.fileNotReachable))
            return
        }
        
        // UTI/파일명 만들기
        guard let videoInfo = makeVideoResourceOptions(for: fileURL) else {
            let ext = fileURL.pathExtension.lowercased()
            completion(.failure(PhotoAlbumHelperError.unsupportedVideoType(ext)))
            return
        }
        
        let options = PHAssetResourceCreationOptions()
        options.uniformTypeIdentifier = videoInfo.uti
        options.originalFilename = videoInfo.fileName
        
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            // 리소스로 비디오 추가 (이 방식이 파일명/UTI 지정에 유리)
            req.addResource(with: .video, fileURL: fileURL, options: options)
            
            if let changeReq = PHAssetCollectionChangeRequest(for: album),
               let ph = req.placeholderForCreatedAsset {
                changeReq.addAssets([ph] as NSArray)
            }
        }, completionHandler: { success, error in
            if success {
                completion(.success(()))
            } else if let error {
                completion(.failure(PhotoAlbumHelperError.photosFrameworkError(error.localizedDescription)))
            } else {
                completion(.failure(PhotoAlbumHelperError.unknown))
            }
        })
    }
    
    // 여러 비디오 순차 저장 (첫 실패에서 중단)
    fileprivate func saveVideos(_ fileURLs: [URL],
                                toAlbumId albumId: String,
                                completion: @escaping (PhotoAlbumHelperVoidResult) -> Void) {
        
        var index = 0
        func step() {
            if index >= fileURLs.count {
                completion(.success(()))
                return
            }
            saveVideo(fileURLs[index], toAlbumId: albumId) { result in
                switch result {
                case .success:
                    index += 1
                    step()
                case .failure(let e):
                    completion(.failure(e))
                }
            }
        }
        step()
    }

}

//MARK About HEIC
extension PhotoAlbumHelper {
    fileprivate func makeImageDataInfo(image:UIImage, format:SaveImageFormat) -> ImageDataInfo? {
        let ts = Int(Date().timeIntervalSince1970)
        
        switch format {
        case .jpeg(let quality):
            guard let data = image.jpegData(compressionQuality: quality) else { return nil }
            Logger.log("make jpeg data")
            return ImageDataInfo(data: data, uti: UTType.jpeg.identifier, fileName: "IMG_\(ts).jpg")
        case .png:
            guard let data = image.pngData() else { return nil }
            Logger.log("make png data")
            return ImageDataInfo(data: data, uti: UTType.png.identifier, fileName: "IMG_\(ts).png")
        case .heic(let quality, let fallbackToJPEG):
            if supportsHEIC(), let data = encodeHEIC(image: image, quality: quality) {
                Logger.log("make heic data")
                return ImageDataInfo(data: data, uti: UTType.heic.identifier, fileName: "IMG_\(ts).heic")
            } else if fallbackToJPEG, let data = image.jpegData(compressionQuality: quality) {
                Logger.log("make fail heic data -> make jpeg data")
                return ImageDataInfo(data: data, uti: UTType.jpeg.identifier, fileName: "IMG_\(ts).jpg")
            }
            return nil
        }
    }
    
    fileprivate func supportsHEIC() -> Bool {
        guard let types = CGImageDestinationCopyTypeIdentifiers() as? [CFString] else { return false }
        return types.contains(UTType.heic.identifier as CFString)
    }
    
    fileprivate func encodeHEIC(image: UIImage, quality: CGFloat) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) else{
            return nil
        }
        let options = [kCGImageDestinationLossyCompressionQuality:quality] as CFDictionary
        CGImageDestinationAddImage(dest, cgImage, options)
        return CGImageDestinationFinalize(dest) ? (data as Data) : nil
    }
}
