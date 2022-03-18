//
//  WebView+imageurls.swift
//  InstagramDownload
//
//  Created by JinGu on 2021/09/17.
//

import UIKit
import WebKit

struct Content {
    
    enum ContentType : String {
        case image
        case video
    }
    
    var type : ContentType
    
    //공통
    var imageURL : String //이미지(video의 경우 썸네일) 주소이기때문에 not nil
    var image : UIImage? //이미지를 받기 전에는 nil
    
    //type image
    var imageSize : String?
    
    //type video
    var videoURL : String?
    
    static func readContents(wkWebView:WKWebView, complete:@escaping(_:[Content])->Void) {
        Self.readHtmlString(wkWebView: wkWebView) { htmlString in
            Self.findContents(htmlString: htmlString) { complete($0) }
        }
    }
    
    static func readHtmlString(wkWebView:WKWebView, complete:@escaping(_:String)->Void){
        wkWebView.evaluateJavaScript(
            "document.documentElement.outerHTML.toString()",
            completionHandler:
                { (html: Any?, error: Error?) in
                    if let htmlString = html as? String {
                        complete(htmlString)
                    }
                })
    }
    
    static func findContents(htmlString : String, complete:@escaping(_:[Content])-> Void){
        
        var contents = [Content]()
        
        Self.findImageContent(htmlString: htmlString) {
            contents += $0
            self.findVideoContent(htmlString: htmlString) {
                contents += $0
                complete(contents)
            }
        }
        
    }
    
    static func findImageContent(htmlString : String, complete:@escaping(_:[Content])-> Void){
        
        var contents = [Content]()
        htmlString.findString(from: "https://", to: "\"", strings: []) { findImageUrlStrings in
            findImageUrlStrings.forEach{ imageUrlString in
                if imageUrlString.contains(".jpg") {
                    let imageUrlString = "https://" + imageUrlString.replacingOccurrences(of: "amp;", with: "")
//                    print("--------imageUrlString:\(imageUrlString)")
                    contents.append(Content(type: .image, imageURL: imageUrlString, imageSize: ""))
                }
            }
            complete(contents)
        }
    }
    
    static func findVideoContent(htmlString : String, complete:@escaping(_:[Content])-> Void){
        
        var contents = [Content]()
        
        htmlString.findString(from: "type=\"video/mp4\" ", to: "></div>", strings: []) {
            findVideoUrlStrings in
            /*
             형태
             src="video url" src="thumnail url"
             */
            
            if findVideoUrlStrings.count == 0 { complete(contents); return }
            
            var count = findVideoUrlStrings.count
            findVideoUrlStrings.forEach { findVideoUrlString in
                findVideoUrlString.findString(from: "src=\"", to: "\"", strings: []) { urls in
                    if urls.count == 2 {
                        print("--------videoUrl:\(urls[0].replacingOccurrences(of: "amp;", with: ""))")
                        print("--------videoImageUrl:\(urls[1].replacingOccurrences(of: "amp;", with: ""))")
                        contents.append(Content(type: .video, imageURL: urls[1].replacingOccurrences(of: "amp;", with: ""), videoURL: urls[0].replacingOccurrences(of: "amp;", with: "")))
                    }
                    count -= 1 //못 찾더라도 클로저가 실행된다는 가정이 포함되어있다
                    if count <= 0 {
                        complete(contents) //todo modify
                    }
                }
            }
        }
        
    }
}

extension WebView {
    
    func readContents(complete:@escaping(_:[Content])->Void) {
        readHtmlString { htmlString in
            
        }
    }
    
    func findUrlString(htmlString:String, complete:@escaping(_:[String])-> Void) {
        
    }

    func readMp4Urls(complete:@escaping(_:[[String:Any]])->Void) {

        readHtmlString {
            self.findMp4UrlString(htmlString: $0) { urlStrings in
                var urlDics = [[String:Any]]()
                urlStrings.forEach{
                    self.divideMp4UrlString(urlBlock: $0) { urlDic in
                        urlDics.append(urlDic)
                        if urlDics.count == urlStrings.count {
                            complete(urlDics)
                        }
                    }
                }
            }
        }
        
    }
    
    func findMp4UrlString(htmlString : String, complete:@escaping(_:[String])-> Void){
//        htmlString.findString(from: "type=\"video/mp4\" src=\"", to: "\"></div>", strings: []) { findStrings in
        htmlString.findString(from: "type=\"video/mp4\" ", to: "></div>", strings: []) { findStrings in
            complete(findStrings)
        }
    }
    
    func divideMp4UrlString(urlBlock:String, complete:@escaping(_:[String:Any])->Void) {
        urlBlock.findString(from: "src=\"", to: "\"", strings: []) { findStrings in
            if findStrings.count == 2 {
                complete([
                    "url":findStrings[0].replacingOccurrences(of: "amp;", with: ""),
                    "thumnail":findStrings[1].replacingOccurrences(of: "amp;", with: "")
                ])
                }
        }
    }
    
    
    func readImageUrls(complete:@escaping(_:[[String:Any]])->Void) {
        
        readHtmlString {
            print("readHtmlString:\($0)\nendhtmlString")
            self.findImageUrlString(htmlString: $0) { urlStrings in
//                print("urlStrings:\(urlStrings.count)")
                var urls = [[String:Any]]()
                urlStrings.forEach{ urlBlocks in
//                    print("urlBlocks:\(urlBlocks)")
                    let originUrls = self.divideImageUrlString(urlBlock: urlBlocks)
                    var maxSize = 0
                    var maxSizeUrl = [String:Any]()
                    originUrls.forEach{url in
                        if url.count != 0,
                           let sizevalue = url["size"] as? String,
                           let size = Int(sizevalue, radix: 10),
                           size > maxSize {
                            maxSize = size
                            maxSizeUrl = url
                        }
                    }
                    if maxSizeUrl.count == 2 { urls.append(maxSizeUrl) }
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
    //?/
    func findImageUrlString(htmlString : String, complete:@escaping(_:[String])-> Void){
        htmlString.findString(from: "srcset=\"", to: "\"", strings: []) { findStrings in
            complete(findStrings)
        }
    }
    
    func divideImageUrlString(urlBlock:String) -> [[String:Any]] {
        let blocks = urlBlock.components(separatedBy: ",")
        return blocks.map { block -> [String:Any] in
            let blockComponent = block.components(separatedBy: " ")
            if blockComponent.count == 2, blockComponent[1].contains("1080") {
                return [
                    "size":blockComponent[1].replacingOccurrences(of: "w", with: ""),
                    "url":blockComponent[0].replacingOccurrences(of: "amp;", with: ""),
                ]
            }else{
                return [String:Any]()
            }
        }
    }
    
    

    
}





