//
//  MediaDetailViewController.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.
//

import Photos
import UIKit

class MediaDetailPageViewController: UIPageViewController, UIPageViewControllerDataSource {

    let mediaItems: [MediaItem]
    var startIndex: Int

    init(mediaItems: [MediaItem], startIndex: Int) {
        self.mediaItems = mediaItems
        self.startIndex = startIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveCurrentMedia))

        let startVC = makePageViewController(at: startIndex)
        setViewControllers([startVC], direction: .forward, animated: false, completion: nil)
    }

    func makePageViewController(at index: Int) -> MediaPageContentViewController {
        let item = mediaItems[index]
        let vc = MediaPageContentViewController(mediaItem: item)
        vc.index = index
        return vc
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? MediaPageContentViewController else { return nil }
        let newIndex = vc.index - 1
        return (newIndex >= 0) ? makePageViewController(at: newIndex) : nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? MediaPageContentViewController else { return nil }
        let newIndex = vc.index + 1
        return (newIndex < mediaItems.count) ? makePageViewController(at: newIndex) : nil
    }

    @objc func saveCurrentMedia() {
        guard let currentVC = viewControllers?.first as? MediaPageContentViewController else { return }
        currentVC.saveMedia()
    }
}

class MediaPageContentViewController: UIViewController {

    var index: Int = 0
    let mediaItem: MediaItem
    let imageView = UIImageView()
    let hud = UIActivityIndicatorView(style: .large)
    var playerLayer: AVPlayerLayer?

    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        imageView.frame = view.bounds
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)

        if mediaItem.type == .video {
            playVideoPreview()
        } else {
            loadPreviewImage()
        }
    }

    func loadPreviewImage() {
        guard let url = URL(string: mediaItem.previewURL.isEmpty ? mediaItem.url : mediaItem.previewURL) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.imageView.image = img
                }
            }
        }.resume()
    }

    func playVideoPreview() {
        guard let url = URL(string: mediaItem.url) else { return }
        let player = AVPlayer(url: url)
        let layer = AVPlayerLayer(player: player)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspect
        view.layer.insertSublayer(layer, above: imageView.layer)
        player.play()
        player.isMuted = true
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        self.playerLayer = layer
    }

    func saveMedia() {

        if mediaItem.type == .image {
            Logger.log("checkPoint1")
            ImageLoader.shared.loadImage(mediaItem.url) { [weak self] image in
                guard let image else {
                    self?.showError("이미지를 저장할 수 없습니다.")
                    return
                }
                PhotoAlbumHelper.shared.saveImageToInstaDownload(image, format: .heic(quality: 1, fallbackToJPEG: true)) { result in
                    switch result {
                    case .success:
                        self?.showAlert("이미지를 저장하였습니다.")
                    case .failure(let error):
                        self?.showError("이미지 저장에 실패하였습니다\n\(error.localizedDescription)")
                    }
                }
            }
        } else {
//            let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempVideo.mp4")ㅁㄴㅇㄹㅁㄴㅇㄹ
//            URLSession.shared.downloadTask(with: url) { localURL, _, _ in
//                guard let localURL = localURL else {
//                    DispatchQueue.main.async {
//                        self.hud.stopAnimating()
//                        self.hud.removeFromSuperview()
//                        self.showError("비디오 다운로드 실패")
//                    }
//                    return
//                }
//                try? FileManager.default.removeItem(at: tempFile)
//                try? FileManager.default.moveItem(at: localURL, to: tempFile)
//
//                PHPhotoLibrary.shared().performChanges({
//                    let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempFile)
//                    let placeholder = request?.placeholderForCreatedAsset
//                    self.addAssetToAlbum(placeholder)
//                }, completionHandler: { success, error in
//                    DispatchQueue.main.async {
//                        self.hud.stopAnimating()
//                        self.hud.removeFromSuperview()
//                        if let error = error {
//                            let errorString = "비디오 저장 실패: \(error.localizedDescription)"
//                            print(errorString)
//                            self.showError(errorString)
//                        } else {
//                            self.showAlert("비디오가 저장되었습니다.")
//                        }
//                    }
//                })
//            }.resume()
        }
    }
}

