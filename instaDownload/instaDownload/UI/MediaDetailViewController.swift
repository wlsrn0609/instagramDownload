//
//  MediaDetailViewController.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.
//

import Photos
import UIKit

class MediaDetailPageViewController: UIPageViewController, UIPageViewControllerDataSource {

    let medias: [Media]
    let cashe : [String:CellRenderable]
    var startIndex: Int

    init(medias: [Media], startIndex: Int, cashe: [String:CellRenderable]) {
        self.medias = medias
        self.startIndex = startIndex
        self.cashe = cashe
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
        let media = medias[index]
        let vc = MediaPageContentViewController(media: media, cashe: self.cashe)
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
        return (newIndex < medias.count) ? makePageViewController(at: newIndex) : nil
    }

    @objc func saveCurrentMedia() {
        guard let currentVC = viewControllers?.first as? MediaPageContentViewController else { return }
        currentVC.saveMedia()
    }
}

class MediaPageContentViewController: UIViewController {

    var index: Int = 0
    let media: Media
    let cashe : [String:CellRenderable]
    let imageView = UIImageView()
    let hud = UIActivityIndicatorView(style: .large)
    var playerLayer: AVPlayerLayer?

    init(media: Media, cashe: [String:CellRenderable]) {
        self.media = media
        self.cashe = cashe
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
        
        if let cellRenderable = self.cashe[self.media.urlString] {
            configure(with: cellRenderable)
        }
    }

    func configure(with cellRenderable: CellRenderable){
        switch cellRenderable {
        case .photo(let image, _):
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        case .video(let thumbnail, let localURL, let originalURL):
            
            let player = AVPlayer(url: localURL)
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
    }

    func saveMedia() {
        MediaSaver.shared.downloadAndSaveMedia(self.media, imageFormat: .heic(quality: 1, fallbackToJPEG: true)) { [weak self] result in
            switch result {
            case .success(let success):
                DispatchQueue.main.async {
                    self?.showAlert("저장하였습니다")
                }
                
            case .failure(let failure):
                self?.showError("저장에 실패하였습니다\n\(failure.localizedDescription)")
            }
        }
    }
}

