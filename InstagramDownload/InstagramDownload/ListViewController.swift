//
//  ListViewController.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit
import SDWebImage
import FontAwesome_swift

enum ContentType : String {
    case image = "image"
    case mp4 = "mp4"
}

class ListViewController : UIViewController {
    
    var tableView : UITableView!

    var contents = [Content]()
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.white
        
        let statusBar = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN.WIDTH, height: STATUS_BAR_HEIGHT))
        statusBar.backgroundColor = UIColor.lightGray
        self.view.addSubview(statusBar)
        
        let naviBar = UIView(frame: CGRect(x: 0, y: statusBar.frame.maxY, width: SCREEN.WIDTH, height: 50))
        naviBar.backgroundColor = UIColor.lightGray
        self.view.addSubview(naviBar)
        
        let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        closeButton.setTitle("Close", for: .normal)
        closeButton.frame.origin.x = naviBar.frame.width - closeButton.frame.width
        naviBar.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        
        tableView = UITableView(frame: CGRect(x: 0, y: naviBar.frame.maxY, width: SCREEN.HEIGHT, height: SCREEN.HEIGHT - naviBar.frame.maxY))
        tableView.register(ListViewTableViewCell.self, forCellReuseIdentifier: "ListViewTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
    }
    
    @objc func closeButtonPressed(){
        self.dismiss(animated: true, completion: nil)
    }
}

extension ListViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListViewTableViewCell", for: indexPath) as? ListViewTableViewCell else { return UITableViewCell() }
        
        cell.index = indexPath.row
        cell.delegate = self
        
        var content = contents[indexPath.row]
        
        if content.type == .image {
            cell.typeImageView.image = UIImage.fontAwesomeIcon(name: .image, style: .solid, textColor: .black.withAlphaComponent(0.3), size: cell.typeImageView.frame.size)
//            cell.downloadButton.setImage(UIImage.fontAwesomeIcon(name: .image, style: .solid, textColor: UIColor.lightGray.withAlphaComponent(0.7), size: CGSize(width: 50, height: 50)), for: .normal)
        }else{
            cell.typeImageView.image = UIImage.fontAwesomeIcon(name: .video, style: .solid, textColor: .black.withAlphaComponent(0.3), size: cell.typeImageView.frame.size)
//            cell.downloadButton.setImage(UIImage.fontAwesomeIcon(name: .video, style: .solid, textColor: UIColor.lightGray.withAlphaComponent(0.7), size: CGSize(width: 50, height: 50)), for: .normal)
        }
        
//        cell.valueLabel.text = content.type.rawValue
        let url = content.imageURL
        Server.postData(urlString: url, method: .get, otherInfo: [:]) { kData in
            if let data = kData {
                if let instaImage = UIImage(data: data) {
                    content.image = instaImage
                    self.contents[indexPath.row] = content
                    
                    cell.setImage(image: instaImage)
                    cell.valueLabel.text = "\(content.imageSize ?? "") " + "\(Int(instaImage.size.width)) x \(Int(instaImage.size.height))"
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}

extension ListViewController : ListViewTableViewCellDelegate {
    
    func downloadButtonPressed(index: Int) {
        
        let content = contents[index]
        
        if content.type == .image {
            if let contentImage = content.image {
                UIImageWriteToSavedPhotosAlbum(contentImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }else{
            if let videoURL = content.videoURL {
                appDel.showHud()
                saveVideo(urlString: videoURL) { success in
                    DispatchQueue.main.async {
                        appDel.hideHud()
                        if success {
                            let alertCon = UIAlertController(title: "안내", message: "저장되었습니다", preferredStyle: .alert)
                            alertCon.addAction(UIAlertAction(title: "확인", style: .cancel, handler: {_ in}))
                            self.present(alertCon, animated: true, completion: {})
                        }
                    }
                }
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error{
            print("save image fail \(error.localizedDescription)")
        }else{
            let alertCon = UIAlertController(title: "안내", message: "저장되었습니다", preferredStyle: .alert)
            alertCon.addAction(UIAlertAction(title: "확인", style: .cancel, handler: {_ in}))
            self.present(alertCon, animated: true, completion: {})
        }
    }
}


@objc protocol ListViewTableViewCellDelegate {
    @objc optional func downloadButtonPressed(index:Int)
}

class ListViewTableViewCell : UITableViewCell {
    
    var instaImageView : UIImageView!
    var valueLabel : UILabel!
    var downloadButton : UIButton!
    var typeImageBackView : UIView!
    var typeImageView : UIImageView!
    var index = 0
    var delegate : ListViewTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: SCREEN.WIDTH, height: 100)
        
        self.selectionStyle = .none
        
        instaImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 100, height: 100))
        instaImageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(instaImageView)
        
        downloadButton = UIButton(type: .system)
        downloadButton.frame = CGRect(x: SCREEN.WIDTH - 55, y: 0, width: 45, height: 45)
        downloadButton.center.y = 50
        downloadButton.setImage(UIImage.fontAwesomeIcon(name: .fileDownload, style: .solid, textColor: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), size: CGSize(width: 50, height: 50)), for: .normal)
        downloadButton.tintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        downloadButton.addTarget(self, action: #selector(downloadButtonPressed), for: .touchUpInside)
        self.contentView.addSubview(downloadButton)
        
        valueLabel = UILabel(frame: CGRect(x: instaImageView.frame.maxX + 10, y: 0, width: downloadButton.frame.minX - (instaImageView.frame.maxX + 10), height: 100))
        valueLabel.textColor = UIColor.darkGray
        self.contentView.addSubview(valueLabel)
     
        typeImageBackView = UIView(frame: instaImageView.bounds)
        typeImageBackView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        instaImageView.addSubview(typeImageBackView)
        
        typeImageView = UIImageView(frame: typeImageBackView.bounds)
        typeImageView.frame.size.width *= 0.3
        typeImageView.frame.size.height *= 0.3
        typeImageView.frame.origin.x = typeImageBackView.frame.width - typeImageView.frame.size.width
        typeImageView.frame.origin.y = 0
        typeImageBackView.addSubview(typeImageView)
    }
    
    @objc func downloadButtonPressed(){
        self.delegate?.downloadButtonPressed?(index: self.index)
    }
    
    func setImage(image:UIImage?){
        guard let image = image else { return }
        
        image.downSample(pointSize: self.instaImageView.frame.size, complete: {
            self.instaImageView.image = $0
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
