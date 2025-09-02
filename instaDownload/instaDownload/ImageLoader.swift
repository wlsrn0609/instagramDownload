//
//  ImageLoader.swift
//  instaDownload
//
//  Created by 권진구 on 8/29/25.
//

import UIKit
import CryptoKit

public final class ImageLoader {
    public static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let ioQueue = DispatchQueue(label: "image.disk.cache")
    private let taskQueue = DispatchQueue(label: "image.loader.tasks")   // 태스크 사전 보호
    
    // 🔹 이미지/비디오 공용으로 태스크 관리
    private var tasks: [NSURL: URLSessionDataTask] = [:]
    
    private lazy var videoDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    private lazy var diskDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.urlCache = nil
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    private init() {
        cache.totalCostLimit = 150 * 1024 * 1024
    }

    // MARK: - Images
    public func loadImages(index: Int = 0, images:[UIImage] = [UIImage](), urlStrings: [String], completion: @escaping ([UIImage]) -> Void) {
        Logger.log("index:\(index), urlStrings.count:\(urlStrings.count)")
        
        var images: [UIImage] = images
        
        //count가 N인 경우, index는 0부터 N-1
        let N = urlStrings.count
        if index <= N - 1 {
            Logger.log("loads index + 1 실행")
                        
            self.loadImage(urlStrings[index]) { image in
                if let image {
                    images.append(image)
                    self.loadImages(index: index + 1, images:images, urlStrings: urlStrings, completion: completion)
                }
            }
        }else{
            Logger.log("loads 종료")
            completion(images)
        }
    }
    
    @discardableResult
    public func loadImage(_ urlString: String, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return nil
        }
        let nsURL = url as NSURL

        // 1) 메모리 캐시
        if let img = cache.object(forKey: nsURL) {
            DispatchQueue.main.async { completion(img) }
            return nil
        }

        // 2) 디스크 캐시
        let diskURL = imageDiskURLFor(urlString: url.absoluteString)
        if let data = try? Data(contentsOf: diskURL),
           let img = UIImage(data: data) {
            cache.setObject(img, forKey: nsURL, cost: img.cacheCost)
            DispatchQueue.main.async { completion(img) }
            return nil
        }

        // 3) 네트워크
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let task = session.dataTask(with: req) { [weak self] data, _, _ in
            guard let self else { return }
            defer {
                // 작업 종료 후 보관된 태스크 제거
                self.taskQueue.async { self.tasks[nsURL] = nil }
            }

            guard let data, let img = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // 디스크 저장
            self.ioQueue.async { try? data.write(to: diskURL, options: .atomic) }

            // 메모리 캐시
            self.cache.setObject(img, forKey: nsURL, cost: img.cacheCost)

            DispatchQueue.main.async { completion(img) }
        }

        // 태스크 보관
        taskQueue.async { self.tasks[nsURL] = task }
        task.resume()
        return task
    }
    
    

    /// URL 기준으로 진행 중 요청을 취소
    public func cancel(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let nsURL = url as NSURL
        taskQueue.async {
            if let task = self.tasks[nsURL] {
                task.cancel()
                self.tasks[nsURL] = nil
            }
        }
    }
    
    private func imageDiskURLFor(urlString: String) -> URL {
        let name = urlString.sha256Hex() + ".img"
        return diskDir.appendingPathComponent(name)
    }
    
    //MARK: Video download
    
    /// 여러 동영상을 순차로 내려받아 로컬 file URL 배열로 반환
    public func loadVideos(index: Int = 0,
                           fileURLs: [URL] = [],
                           urlStrings: [String],
                           completion: @escaping ([URL]) -> Void) {
        var acc = fileURLs
        let N = urlStrings.count
        if index <= N - 1 {
            loadVideo(urlStrings[index]) { local in
                if let local { acc.append(local) }
                self.loadVideos(index: index + 1, fileURLs: acc, urlStrings: urlStrings, completion: completion)
            }
        } else {
            completion(acc)
        }
    }
    
    @discardableResult
    public func loadVideo(_ urlString: String, completion: @escaping (URL?) -> Void) -> URLSessionDataTask? {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return nil
        }
        let nsURL = url as NSURL
        
        // 1) 디스크 캐시 확인
        let cached = videoDiskURLFor(urlString: url.absoluteString)
        if FileManager.default.fileExists(atPath: cached.path) {
            DispatchQueue.main.async { completion(cached) }
            return nil
        }
        
        // 2) 네트워크 다운로드
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = session.dataTask(with: req) { [weak self] data, resp, _ in
            guard let self else { return }
            defer {
                self.taskQueue.async { self.tasks[nsURL] = nil }
            }
            
            guard let data, data.count > 0 else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // 확장자 추론: URL → Content-Type 순
            let ext = self.videoExtension(url: url, response: resp)
            let finalURL = self.videoDiskURLFor(urlString: url.absoluteString, forcedExt: ext)
            
            self.ioQueue.async {
                do {
                    try data.write(to: finalURL, options: .atomic)
                    DispatchQueue.main.async { completion(finalURL) }
                } catch {
                    DispatchQueue.main.async { completion(nil) }
                }
            }
        }
        
        taskQueue.async { self.tasks[nsURL] = task }
        task.resume()
        return task
    }
    


    // 취소는 이미지/비디오 동일 키로 관리
    public func cancelVideo(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let nsURL = url as NSURL
        taskQueue.async {
            if let task = self.tasks[nsURL] {
                task.cancel()
                self.tasks[nsURL] = nil
            }
        }
    }
    
    private func videoDiskURLFor(urlString: String, forcedExt ext: String? = nil) -> URL {
        let name = urlString.sha256Hex() + "." + (ext ?? "mp4")
        return videoDir.appendingPathComponent(name)
    }

    /// URL/path 확장자 또는 Response의 Content-Type으로 합리적 추론
    private func videoExtension(url: URL, response: URLResponse?) -> String {
        let urlExt = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v", "avi"].contains(urlExt) { return urlExt }

        if let type = (response as? HTTPURLResponse)?
            .allHeaderFields["Content-Type"] as? String {
            if type.contains("mp4") { return "mp4" }
            if type.contains("quicktime") { return "mov" }
            if type.contains("x-m4v") { return "m4v" }
            if type.contains("avi") { return "avi" }
        }
        return "mp4"
    }
    

}

private extension UIImage {
    var cacheCost: Int {
        guard let cg = self.cgImage else { return 1 }
        return cg.width * cg.height * 4
    }
}

private extension String {
    func sha256Hex() -> String {
        let digest = SHA256.hash(data: Data(self.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
