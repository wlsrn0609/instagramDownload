//
//  WebView.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit
import WebKit

class WebView: UIView
,WKNavigationDelegate , WKUIDelegate
{
    var wkWebView : WKWebView!
    var urlString = ""
    
    init(frame: CGRect, urlString : String) {
        super.init(frame: frame)
        
        print("WebView url:\(urlString)")
    
        self.backgroundColor = UIColor.white
        
        self.wkWebView = WKWebView(frame: self.bounds)
        self.wkWebView.uiDelegate = self
        self.wkWebView.navigationDelegate = self
        self.wkWebView.scrollView.bounces = false
        self.addSubview(self.wkWebView)
        
        self.urlString = urlString
        self.reloading()
        
    }
    
    func reloading(){
        
        if let url = URL(string: self.urlString) {
            let request = URLRequest(url: url)
            self.wkWebView.load(request)
        }else{
            print("urlErro : \(urlString)")
            toastShow(message: "Check your internet connection.")
        }
    }
    
    
    
    //MARK:WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        print("createWebViewWith:\(String(describing: navigationAction.request.url?.absoluteString))")
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
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!){
        print(#function)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        print(#function)
        
//        webView.evaluateJavaScript(kTouchJavaScriptString) { (result : Any?, error : Error?) in  }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error){
        print(#function)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertCon = UIAlertController(title: "안내", message: message, preferredStyle: .alert)
        alertCon.addAction(UIAlertAction(title: "닫기", style: .cancel, handler: nil))
        
        completionHandler()
    }
    
    
    var confirmPanelValue = 0
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        self.confirmPanelValue = 0
        
        let alertCon = UIAlertController(title: "Notice", message: message, preferredStyle: UIAlertController.Style.alert)
        alertCon.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { (action) in
            self.confirmPanelValue = 1
        }))
        alertCon.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { (action) in
            self.confirmPanelValue = 2
        }))
        
        appDel.mainCon?.present(alertCon, animated: true, completion: {})
        
        while confirmPanelValue == 0 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        
        if confirmPanelValue == 1 {
            completionHandler(true)
        }else{
            completionHandler(false)
        }
        
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




