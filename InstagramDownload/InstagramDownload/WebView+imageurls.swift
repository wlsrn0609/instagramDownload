//
//  WebView+imageurls.swift
//  InstagramDownload
//
//  Created by JinGu on 2021/09/17.
//

import Foundation

extension WebView {

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
