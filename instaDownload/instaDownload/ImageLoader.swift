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
    private var tasks: [NSURL: URLSessionDataTask] = [:]

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

    public func loads(index: Int = 0, images:[UIImage] = [UIImage](), urlStrings: [String], completion: @escaping ([UIImage]) -> Void) {
        Logger.log("index:\(index), urlStrings.count:\(urlStrings.count)")
        
        var images: [UIImage] = images
        
        //count가 N인 경우, index는 0부터 N-1
        let N = urlStrings.count
        if index <= N - 1 {
            Logger.log("loads index + 1 실행")
                        
            self.load(urlStrings[index]) { image in
                if let image = image {
                    images.append(image)
                    self.loads(index: index + 1, images:images, urlStrings: urlStrings, completion: completion)
                }
            }
        }else{
            Logger.log("loads 종료")
            completion(images)
        }
    }
    
    @discardableResult
    public func load(_ urlString: String, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
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
        let diskURL = diskURLFor(urlString: url.absoluteString)
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

    private func diskURLFor(urlString: String) -> URL {
        let name = urlString.sha256Hex() + ".img"
        return diskDir.appendingPathComponent(name)
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
