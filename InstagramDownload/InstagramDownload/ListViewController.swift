//
//  ListViewController.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit
import SDWebImage

class ListViewController : UIViewController {
    
    var urlStrings = [String]()
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
        
        cell.textLabel?.text = urlStrings[indexPath.row]
        print("\(urlStrings[indexPath.row])")
        if let url = URL(string: urlStrings[indexPath.row]) {
            OperationQueue.main.addOperation {
                cell.instaImageView.sd_setImage(with: url) { image, error, type, url in
                    if let error = error {
                        cell.textLabel?.text = error.localizedDescription
                    }
                }
                cell.instaImageView.sd_setImage(with: url, completed: nil)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}

class ListViewTableViewCell : UITableViewCell {
    var instaImageView : UIImageView!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: SCREEN.WIDTH, height: 100)
        
        instaImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 100, height: 100))
        self.addSubview(instaImageView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
