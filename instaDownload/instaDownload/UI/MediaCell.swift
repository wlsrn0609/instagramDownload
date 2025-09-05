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
    
    // 이 셀에 현재 바인딩된 미디어 키
    var representedKey: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        representedKey = nil
        imageView.image = nil
        videoIcon.isHidden = true
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
}

