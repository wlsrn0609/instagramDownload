//
//  js.swift
//  instaDownload
//
//  Created by 권진구 on 8/29/25.
//

import Foundation



struct JSCode {
  static let goToMoveFirst = """
        (async function() {
            for (let i = 0; i < 100; i++) {
                let prevBtn = document.querySelector('button[aria-label="이전"], button[aria-label="Previous"]');
                if (!prevBtn) break;
                prevBtn.click();
                await new Promise(r => setTimeout(r, 300));
            }
            return true;
        })();
        """
    
    static let gotoNext = """
    (function() {
        let btn = document.querySelector('button[aria-label="다음"], button[aria-label="Next"]');
        if (btn) { btn.click(); return true; }
        return false;
    })();
    """
        
    static let getMedia = """
        (function() {
            const urls = [];

            // 1) 비디오 먼저
            let video = document.querySelector("article video");
            if (video && video.src) {
                urls.push(video.src);
            }

            // 2) 이미지 후보들
            let imgs = Array.from(document.querySelectorAll("article img"));
            let validImgs = imgs.filter(img => {
                const w = img.naturalWidth || img.width;
                const h = img.naturalHeight || img.height;
                return w >= 200 && h >= 200 && !img.src.includes("profile");
            });

            validImgs.forEach(img => {
                if (img.srcset) {
                    let candidates = img.srcset.split(',')
                        .map(s => s.trim().split(' ')[0]);
                    if (candidates.length > 0) {
                        urls.push(candidates[candidates.length - 1]); // 가장 큰 해상도
                    }
                } else if (img.src) {
                    urls.push(img.src);
                }
            });

            // 결과를 "url,url,url" 형태의 문자열로 반환
            return urls.join(",");
        })();
    """
    
    
    
    static func collectAllJSForLastItem(postId:String) -> String {
        return """
    (function() {
        let articles = document.querySelectorAll("article");
        for (let i = 0; i < articles.length; i++) {
            let links = articles[i].querySelectorAll("a[href*='/p/']");
            for (let j = 0; j < links.length; j++) {
                if (links[j].href.includes('\(postId)')) {
                    let media = [];
                    let videos = articles[i].querySelectorAll("video");
                    for (let v of videos) {
                        if (v.src) media.push(v.src);
                    }
                    let imgs = articles[i].querySelectorAll("img");
                    for (let img of imgs) {
                        const w = img.naturalWidth || img.width;
                        const h = img.naturalHeight || img.height;
                        if (w >= 200 && h >= 200 && !img.src.includes("profile")) {
                            if (img.srcset) {
                                let candidates = img.srcset.split(',').map(s => s.trim().split(" ")[0]);
                                if (candidates.length > 0) media.push(candidates[candidates.length - 1]);
                            } else {
                                media.push(img.src);
                            }
                        }
                    }
                    return [...new Set(media)];
                }
            }
        }
        return [];
    })();
    """
    }
}
