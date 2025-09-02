//
//  MediaListViewController.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.
//

import UIKit
import AVKit
import Photos

class MediaListViewController: UICollectionViewController {

    let mediaItems: [MediaItem]

    init(mediaItems: [MediaItem]) {
        self.mediaItems = mediaItems
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .white
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "전체 저장", style: .plain, target: self, action: #selector(saveAllMedia))
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
        let item = mediaItems[indexPath.item]
        cell.configure(with: item)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailVC = MediaDetailPageViewController(mediaItems: mediaItems, startIndex: indexPath.item)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc func saveAllMedia() {
        
//        let urls = mediaItems.compactMap {
//            $0.type == .image ? $0.url : nil
//        }
//        ImageLoader.shared.loadImages(urlStrings: urls) { [weak self] in
//            Logger.log("image load complete:\($0)")
//            PhotoAlbumHelper.shared.saveImagesToInstaDownload($0, format: .heic(quality: 1, fallbackToJPEG: true)) { result in
//                switch result {
//                case .success:
//                    self?.showAlert("이미지를 저장하였습니다")
//                case .failure(let error):
//                    self?.showError("이미지 저장에 실패하였습니다\n\(error.localizedDescription)")
//                }
//            }
//        }
        let urls = mediaItems.compactMap {
            $0.type == .video ? $0.url : nil
        }
        MediaDownloader.shared.loadVideos(urlStrings: urls) { [weak self] urls in
            Logger.log("video load complete:\(urls)")
            PhotoAlbumHelper.shared.saveVideosToInstaDownload(urls) { result in
                switch result {
                case .success:
                    self?.showAlert("영상을 저장하였습니다")
                case .failure(let error):
                    self?.showError("영상 저장에 실패하였습니다\n\(error.localizedDescription)")
                }
            }
        }
        
//        let hud = UIActivityIndicatorView(style: .large)
//        hud.center = view.center
//        view.addSubview(hud)
//        hud.startAnimating()
//
//        let group = DispatchGroup()
//        let queue = DispatchQueue(label: "com.insta.saveQueue")
//
//        for item in mediaItems {
//            group.enter()
//            queue.async {
//                guard let url = URL(string: item.url) else {
//                    group.leave()
//                    return
//                }
//
//                if item.type == .image {
//                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
//                        self.saveImageToAlbum(image)
//                    }
//                    group.leave()
//                } else {
//                    let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
//                    URLSession.shared.downloadTask(with: url) { localURL, _, _ in
//                        if let localURL = localURL {
//                            try? FileManager.default.removeItem(at: tempFile)
//                            try? FileManager.default.moveItem(at: localURL, to: tempFile)
//
//                            PHPhotoLibrary.shared().performChanges({
//                                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempFile)
//                                let placeholder = request?.placeholderForCreatedAsset
//                                self.addAssetToAlbum(placeholder)
//                            }) { _, _ in group.leave() }
//                        } else {
//                            group.leave()
//                        }
//                    }.resume()
//                }
//            }
//        }
//
//        group.notify(queue: .main) {
//            hud.stopAnimating()
//            hud.removeFromSuperview()
//            self.showAlert(message: "모든 콘텐츠가 저장되었습니다.", title: "완료")
//        }
    }

    func saveImageToAlbum(_ image: UIImage) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeholder = request.placeholderForCreatedAsset
        }) { success, error in
            if success, let placeholder = placeholder {
                self.addAssetToAlbum(placeholder)
            } else if let error = error {
                print("저장 실패: \(error.localizedDescription)")
            }
        }
    }

    func addAssetToAlbum(_ assetPlaceholder: PHObjectPlaceholder?) {
        guard let placeholder = assetPlaceholder else { return }
        let albumName = "InstaDownload"
        var album: PHAssetCollection?

        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        fetch.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == albumName {
                album = collection
                stop.pointee = true
            }
        }

        if let album = album {
            PHPhotoLibrary.shared().performChanges {
                let albumChange = PHAssetCollectionChangeRequest(for: album)
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                albumChange?.addAssets(asset)
            }
        } else {
            PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }
        }
    }

//    func showAlert(message: String, title: String = "알림") {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "확인", style: .default))
//        present(alert, animated: true)
//    }
}



