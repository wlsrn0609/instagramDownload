//
//  MediaCell.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.
//

import Foundation
import UIKit

import UIKit

class MediaCell: UICollectionViewCell {
    let imageView = UIImageView()
    let videoIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
    private var currentURLString: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        if let url = currentURLString {
            MediaDownloader.shared.cancel(url)
        }
        currentURLString = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.frame = contentView.bounds

        videoIcon.tintColor = .white
        videoIcon.contentMode = .scaleAspectFit
        videoIcon.alpha = 0.8
        contentView.addSubview(videoIcon)
        videoIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoIcon.widthAnchor.constraint(equalToConstant: 30),
            videoIcon.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with cellRenderable: CellRenderable){
        switch cellRenderable {
        case .photo(let image, _):
            DispatchQueue.main.async {
                self.imageView.image = image
                self.videoIcon.isHidden = true
            }
        case .video(let thumbnail, _, _):
            DispatchQueue.main.async {
                self.imageView.image = thumbnail
                self.videoIcon.isHidden = false
            }
        }
    }
    
//    func configure(with media: Media) {
//        MediaSaver.shared.downloadForDisplay([media]) { [weak self] result in
//            guard let self else { return }
//            switch result {
//            case .success(let success):
//                guard let cellRenderable = success.first else { return }
//                
//                switch cellRenderable {
//                case .photo(let image, _):
//                    DispatchQueue.main.async {
//                        self.imageView.image = image
//                        self.videoIcon.isHidden = true
//                    }
//                case .video(let thumbnail, _, _):
//                    DispatchQueue.main.async {
//                        self.imageView.image = thumbnail
//                        self.videoIcon.isHidden = false
//                    }
//                }
//                
//            case .failure(let failure):
//                Logger.log("error:\(failure.localizedDescription)")
//            }
//        }
//    }
}

//final class MediaCell: UICollectionViewCell {
//    @IBOutlet private weak var imageView: UIImageView!
//    private var currentURLString: String?
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        imageView.image = nil
//        if let url = currentURLString {
//            ImageLoader.shared.cancel(url)
//        }
//        currentURLString = nil
//    }
//
//    func configure(with item: MediaItem) {
//        let url = item.previewURL.isEmpty ? item.url : item.previewURL
//        currentURLString = url
//
//        _ = ImageLoader.shared.load(url) { [weak self] image in
//            guard let self, self.currentURLString == url else { return }
//            self.imageView.image = image
//        }
//    }
//}
