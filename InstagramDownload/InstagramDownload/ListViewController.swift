//
//  ListViewController.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit
import SDWebImage

enum ContentType : String {
    case image = "image"
    case mp4 = "mp4"
}

class ListViewController : UIViewController {
    
    var urlInfos = [[String:Any]]()
    var tableView : UITableView!

    var type:ContentType = .image
    
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
        urlInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListViewTableViewCell", for: indexPath) as? ListViewTableViewCell else { return UITableViewCell() }
        
        cell.index = indexPath.row
        cell.type = self.type
        cell.delegate = self
        urlInfos[indexPath.row]["type"] = self.type.rawValue
        let dic = urlInfos[indexPath.row]
        
        if self.type == .image {
            cell.valueLabel.text = dic["size"] as? String
            if let url = dic["url"] as? String {
                Server.postData(urlString: url, method: .get, otherInfo: [:]) { kData in
                    if let data = kData {
                        if let instaImage = UIImage(data: data) {
                            self.urlInfos[indexPath.row]["image"] = instaImage
                            cell.setImage(image: instaImage)
                            cell.valueLabel.text = "\(dic["size"] ?? "")w " + "\(Int(instaImage.size.width)) x \(Int(instaImage.size.height))"
                        }
                        
                    }
                }
            }
        }
        if self.type == .mp4 {
            if let url = dic["thumnail"] as? String {
                Server.postData(urlString: url, method: .get, otherInfo: [:]) { kData in
                    if let data = kData {
                        if let instaImage = UIImage(data: data) {
                            cell.setImage(image: instaImage)
                            cell.valueLabel.text = "\(dic["size"] ?? "")w " + "\(Int(instaImage.size.width)) x \(Int(instaImage.size.height))"
                        }
                        
                    }
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
        let dic = urlInfos[index]
        if let typeString = dic["type"] as? String, typeString == "image" {
            if let image = dic["image"] as? UIImage {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }else{
            if let urlString = dic["url"] as? String {
                appDel.showHud()
                saveVideo(urlString: urlString) { success in
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
    
//    func downloadButtonPressed(image: UIImage?) {
//        if self.type = .image {
//            if let image = image {
//                print("downloadButtonPressed:\(image.size)")
//                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
//            }
//        }
//    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error{
            print("save image fail \(error.localizedDescription)")
        }else{
            let alertCon = UIAlertController(title: "안내", message: "저장되었습니다", preferredStyle: .alert)
            alertCon.addAction(UIAlertAction(title: "확인", style: .cancel, handler: {_ in}))
            self.present(alertCon, animated: true, completion: {})
//            toastShow(message: "Complete.")
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
    var index = 0
    var delegate : ListViewTableViewCellDelegate?
    
    var instaImage : UIImage?
    
    var type : ContentType = .image
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: SCREEN.WIDTH, height: 100)
        
        self.selectionStyle = .none
        
        instaImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 100, height: 100))
        instaImageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(instaImageView)
        
        downloadButton = UIButton(type: .system)
        downloadButton.frame = CGRect(x: SCREEN.WIDTH - 85, y: 0, width: 80, height: 35)
        downloadButton.center.y = 50
        downloadButton.setTitle("download", for: .normal)
        downloadButton.setTitleColor(UIColor.gray, for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadButtonPressed), for: .touchUpInside)
        downloadButton.layer.cornerRadius = downloadButton.frame.size.height / 2
        downloadButton.layer.borderWidth = 0.5
        downloadButton.layer.borderColor = UIColor.gray.cgColor
        self.contentView.addSubview(downloadButton)
        
        valueLabel = UILabel(frame: CGRect(x: instaImageView.frame.maxX + 10, y: 0, width: downloadButton.frame.minX - (instaImageView.frame.maxX + 10), height: 100))
        valueLabel.textColor = UIColor.darkGray
        self.contentView.addSubview(valueLabel)
        
    }
    
    @objc func downloadButtonPressed(){
        print("downloadButtonPressed")
        self.delegate?.downloadButtonPressed?(index: self.index)
//        if self.type == .image {
//        self.delegate?.downloadButtonPressed?(image: self.instaImage)
//        }else{
//            self.delegate?.downloadButtonPressed?(mp4UrlString: <#T##String#>)
//        }
    }
    
    func setImage(image:UIImage?){
        guard let image = image else { return }
        
        self.instaImage = image
//        self.valueLabel.text = "\(Int(image.size.width)) x \(Int(image.size.height))"
        print("setImageA:\(image.size)")
        
        image.downSample(pointSize: self.instaImageView.frame.size, complete: {
            self.instaImageView.image = $0
            print("setImageB:\(String(describing: $0?.size))")
            
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
