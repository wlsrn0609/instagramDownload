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

    let medias: [Media]
    private var cashe : [String:CellRenderable] = [:]
    private var inFlight = [String: URLSessionDataTask]()

    init(medias: [Media]) {
        self.medias = medias
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
        return medias.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
        let media = medias[indexPath.item]
        let key = media.urlString
        
        cell.representedKey = key
        
        if let cashedRenderable = cashe[key] {
            cell.configure(with: cashedRenderable)
            return cell
        }
        
        inFlight[key]?.cancel()
        inFlight[key] = nil
        
        let task = MediaSaver.shared.loadRenderable(for: media) { [weak self, weak cell] cellRenderable in
            guard let self else { return }
            DispatchQueue.main.async {
                self.inFlight[key] = nil
                guard let cellRenderable else { return }
                
                guard cell?.representedKey == key else { return }
                if let kIndexPath = collectionView.indexPath(for: cell ?? UICollectionViewCell()), indexPath == kIndexPath {
                    self.cashe[key] = cellRenderable
                    cell?.configure(with: cellRenderable)
                }
            }
        }
        
        if let task { inFlight[key] = task }
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item < medias.count else { return }
        let key = self.medias[indexPath.item].urlString
        inFlight[key]?.cancel()
        inFlight[key] = nil
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailVC = MediaDetailPageViewController(medias: medias, startIndex: indexPath.item, cashe: self.cashe)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc func saveAllMedia() {
        MediaSaver.shared.downloadAndSaveMedias(self.medias, imageFormat: .heic(quality: 1, fallbackToJPEG: true)) { result in
            switch result {
            case .success(_):
                self.showAlert("모두 저장하였습니다")
            case .failure(let error):
                self.showAlert("저장에 실패하였습니다\n\(error.localizedDescription)")
            }
        }
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



