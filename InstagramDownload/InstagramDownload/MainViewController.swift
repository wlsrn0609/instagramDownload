//
//  ViewController.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit

class MainViewController: UIViewController {

    var webView : WebView!
    var urlString = "" {
        willSet(newValue) {
            toastShow(message: newValue)
            self.urlLabel.text = newValue
            self.webView.urlString = newValue
            self.webView.reloading()
        }
    }
    var urlLabel : UILabel!
    var testUrlString = "https://www.instagram.com/p/CTvoo7EJbpg/?utm_medium=copy_link"
    
    var readButton : UIButton!
    var clipBoardButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        self.view.backgroundColor = UIColor.white
        
        let statusBar = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN.WIDTH, height: STATUS_BAR_HEIGHT))
        statusBar.backgroundColor = UIColor.lightGray
        self.view.addSubview(statusBar)
        
        let naviBar = UIView(frame: CGRect(x: 0, y: statusBar.frame.maxY, width: SCREEN.WIDTH, height: 50))
        naviBar.backgroundColor = UIColor.lightGray
        self.view.addSubview(naviBar)
        
        let safeAreaView = UIView(frame: CGRect(x: 0, y: SCREEN.HEIGHT - SAFE_AREA, width: SCREEN.HEIGHT, height: SAFE_AREA))
        safeAreaView.backgroundColor = UIColor.lightGray
        self.view.addSubview(safeAreaView)
        
        let bottomBar = UIView(frame: CGRect(x: 0, y: safeAreaView.frame.minY - 50, width: SCREEN.WIDTH, height: 50))
        bottomBar.backgroundColor = UIColor.lightGray
        self.view.addSubview(bottomBar)
        
        urlLabel = UILabel(frame: CGRect(x: 0, y: naviBar.frame.maxY, width: SCREEN.WIDTH, height: 30))
        urlLabel.backgroundColor = UIColor.lightGray
        urlLabel.textColor = UIColor.white
        urlLabel.textAlignment = .center
        urlLabel.font = UIFont.systemFont(ofSize: urlLabel.frame.height * 0.4)
        self.view.addSubview(urlLabel)
        
        webView = WebView(frame: CGRect(x: 0, y: urlLabel.frame.maxY, width: SCREEN.WIDTH, height: bottomBar.frame.minY - urlLabel.frame.maxY), urlString: urlString)
        self.view.addSubview(webView)
        
        readButton = UIButton(frame: bottomBar.bounds)
        readButton.setTitle("Read", for: .normal)
        bottomBar.addSubview(readButton)
        readButton.addTarget(self, action: #selector(readButtonPressed), for: .touchUpInside)
        
        clipBoardButton = UIButton(frame: naviBar.bounds)
        clipBoardButton.setTitle("클립보드에서 붙여넣기", for: .normal)
        naviBar.addSubview(clipBoardButton)
        clipBoardButton.addTarget(self, action: #selector(clipBoardButtonPressed), for: .touchUpInside)
        
        if let theString = UIPasteboard.general.string {
            self.urlString = theString
        }
    }
    
    @objc func readButtonPressed(){
        webView.readImageUrls {
            let listVC = ListViewController()
            listVC.modalPresentationStyle = .fullScreen
            listVC.urlStrings = $0
            print("listVC.urlStrings:\(listVC.urlStrings)")
            DispatchQueue.main.async {
                self.present(listVC, animated: true) {}
            }
            
        }
        
    }
    
    @objc func clipBoardButtonPressed(){
        if let theString = UIPasteboard.general.string {
            self.urlString = theString
        }
    }
    
    

}

