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
    
    func readImageUrls(complete:@escaping(_:[String])->Void) {
        
        readHtmlString {
//            print("readHtmlString:\($0)")
            self.findImageUrlString(htmlString: $0) { urlStrings in
//            self.findImageUrlString(htmlString: sampleString) { urlStrings in
//                print("urlStrings:\(urlStrings.count)")
                var urls = [String]()
                urlStrings.forEach{ urlBlocks in
//                    print("urlBlocks:\(urlBlocks)")
                    
                    let originUrls = self.divideUrlString(urlBlock: urlBlocks)
                    originUrls.forEach{url in
                        if url.replacingOccurrences(of: " ", with: "") != "" {
//                            last = url
                            urls.append(url)
                        }
                    }
                }
                complete(urls)
            }
        }
        
    }
    
    func readHtmlString(complete:@escaping(_:String)->Void){
        wkWebView.evaluateJavaScript(
            "document.documentElement.outerHTML.toString()",
            completionHandler:
                { (html: Any?, error: Error?) in
                    if let htmlString = html as? String {
                        print("html:\n\(htmlString)")
                        complete(htmlString)
                    }
                })
    }
//    https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=90f4c8516425e2225712f35bcff61b8e&amp;oe=6147ACA5&amp;_nc_sid=83d603 640w
//    https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=90f4c8516425e2225712f35bcff61b8e&amp;oe=6147ACA5&amp;_nc_sid=83d603
    
    func findImageUrlString(htmlString : String, complete:@escaping(_:[String])-> Void){
        htmlString.findString(from: "srcset=\"", to: "\"", strings: []) { findStrings in
            complete(findStrings)
        }
    }
    
    func divideUrlString(urlBlock:String) -> [String] {
        let blocks = urlBlock.components(separatedBy: " ")
//        return blocks
        return blocks.map { block -> String in
            var newBlock = block.replacingOccurrences(of: "640w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "750w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "1080w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "150w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "240w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "320w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "480w", with: "")
            newBlock = newBlock.replacingOccurrences(of: "amp;", with: "")
            newBlock = newBlock.replacingOccurrences(of: ",", with: "")
            return newBlock
        }
    }
  /*
     https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&_nc_cat=1&_nc_ohc=ED6Ul3JjqvUAX___f1S&edm=AABBvjUBAAAA&ccb=7-4&oh=d555f98a0ce10757d94f16bbd06e8f17&oe=6147ACA5&_nc_sid=83d603
     
     
     
     */
    
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




