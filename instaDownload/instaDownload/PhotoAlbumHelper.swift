import Photos
import UIKit

final class PhotoAlbumHelper {
    static let shared = PhotoAlbumHelper()
    private let albumTitle = "InstaDownload"
    private let albumIdKey = "instaDownload.album.localIdentifier"

    
    public func saveImageToInstaDownload(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        self.ensureAlbum { [weak self] albumId in
            guard let albumId = albumId else { completion(false); return }
            self?.saveImage(image, toAlbumId: albumId, completion: completion)
        }
    }
    
    //MARK: private function
    
    /// 앨범의 localIdentifier를 보장해서 completion으로 돌려줌
    private func ensureAlbum(completion: @escaping (String?) -> Void) {
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
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumTitle)
            let id = req.placeholderForCreatedAssetCollection.localIdentifier
            if !id.isEmpty {
                UserDefaults.standard.set(id, forKey: self.albumIdKey)
            }
        }, completionHandler: { success, _ in
            let id = UserDefaults.standard.string(forKey: self.albumIdKey)
            completion(success ? id : nil)
        })
    }
    
    private func saveImage(_ image: UIImage, toAlbumId albumId: String, completion: @escaping (Bool) -> Void) {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject
        else { completion(false); return }

        PHPhotoLibrary.shared().performChanges({
            // 1) 에셋 생성
            let create = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let placeholder = create.placeholderForCreatedAsset else { return }

            // 2) 앨범에 추가
            if let albumReq = PHAssetCollectionChangeRequest(for: album) {
                albumReq.addAssets([placeholder] as NSArray)
            }
        }, completionHandler: { success, _ in
            completion(success)
        })
    }
    
    private func saveVideo(fileURL: URL, toAlbumId albumId: String, completion: @escaping (Bool) -> Void) {
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
