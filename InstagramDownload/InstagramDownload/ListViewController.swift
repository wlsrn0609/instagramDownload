//
//  ListViewController.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit
import SDWebImage

class ListViewController : UIViewController {
    
    var urlStrings = [[String:String]]()
    var tableView : UITableView!
    
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
        urlStrings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListViewTableViewCell", for: indexPath) as? ListViewTableViewCell else { return UITableViewCell() }
        
        let dic = urlStrings[indexPath.row]
        cell.valueLabel.text = dic["size"]
        cell.index = indexPath.row
        cell.delegate = self
        if let url = dic["url"] {
            Server.postData(urlString: url, method: .get, otherInfo: [:]) { kData in
                if let data = kData {
                    if let instaImage = UIImage(data: data) {
                        cell.instaImageView.image = instaImage
                        cell.textLabel?.text = ""
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
    
    func downloadButtonPressed(image: UIImage?) {
        if let image = image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error{
            print("save image fail \(error.localizedDescription)")
        }else{
            toastShow(message: "Complete.")
        }
    }
}


@objc protocol ListViewTableViewCellDelegate {
    @objc optional func downloadButtonPressed(image:UIImage?)
}

class ListViewTableViewCell : UITableViewCell {
    
    var instaImageView : UIImageView!
    var valueLabel : UILabel!
    var downloadButton : UIButton!
    var index = 0
    var delegate : ListViewTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: SCREEN.WIDTH, height: 100)
        
        self.selectionStyle = .none
        
        instaImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 100, height: 100))
        self.contentView.addSubview(instaImageView)
        
        downloadButton = UIButton(type: .system)
        downloadButton.frame = CGRect(x: SCREEN.WIDTH - 60, y: 0, width: 50, height: 30)
        downloadButton.center.y = 50
        downloadButton.setTitle("다운", for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadButtonPressed), for: .touchUpInside)
        downloadButton.layer.cornerRadius = downloadButton.frame.size.height / 2
        downloadButton.setTitleColor(UIColor.black, for: .normal)
        downloadButton.layer.borderWidth = 0.5
        downloadButton.layer.borderColor = UIColor.black.cgColor
        self.contentView.addSubview(downloadButton)
        
        valueLabel = UILabel(frame: CGRect(x: instaImageView.frame.maxX + 10, y: 0, width: downloadButton.frame.minX - (instaImageView.frame.maxX + 10), height: 100))
        self.contentView.addSubview(valueLabel)
        
    }
    
    @objc func downloadButtonPressed(){
        print("downloadButtonPressed")
        self.delegate?.downloadButtonPressed?(image: self.instaImageView.image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
