//
//  WebView.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit
import WebKit

@objc protocol WebViewDelegate {
    @objc optional func didFinishLoad()
}

class WebView: UIView
,WKNavigationDelegate , WKUIDelegate
{
    var wkWebView : WKWebView!
    var urlString = ""
    var delegate : WebViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        self.wkWebView = WKWebView(frame: self.bounds)
        self.wkWebView.uiDelegate = self
        self.wkWebView.navigationDelegate = self
        self.wkWebView.scrollView.bounces = false
        self.addSubview(self.wkWebView)
        
    }
    
    func reloading(){
        
        if let url = URL(string: self.urlString) {
            let request = URLRequest(url: url)
            self.wkWebView.load(request)
        }else{
            print("urlErro : \(urlString)")
//            toastShow(message: "Check your internet connection.")
        }
    }
    
    
    
    //MARK:WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if let absoluteString = navigationAction.request.url?.absoluteString {
            self.urlString = absoluteString
            self.reloading()
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void){
        print(#function)
        decisionHandler(.allow)
        
    }

    func webViewDidClose(_ webView: WKWebView){
        print(#function)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView){
        print(#function)
    }


    //MARK:WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!){
        print(#function)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!){
        print(#function)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error){
        print(#function)
        print("error : \(error.localizedDescription)")
//        self.endEditing(true)

    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        print(#function)
        self.delegate?.didFinishLoad?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




