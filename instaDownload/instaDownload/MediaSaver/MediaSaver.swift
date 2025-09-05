//
//  MediaSaver.swift
//  instaDownload
//
//  Created by 권진구 on 9/2/25.
//

import UIKit
import AVFoundation

/// 미디어 아이템(이미지/영상)을 통일된 타입으로 표현
// Media에 canonicalKey 제공
public enum Media {
    case image(urlString: String)
    case video(urlString: String)

    var urlString: String {
        switch self {
        case .image(let u), .video(let u): return u
        }
    }

    // 쿼리/프래그먼트 제거한 절대경로로 동일성 판단
    var canonicalKey: String {
        guard let u = URL(string: self.urlString) else { return self.urlString }
        let normalized = u.removingQueryAndFragment.absoluteString
        return normalized
    }
}

private extension URL {
    var removingQueryAndFragment: URL {
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: false)
        comps?.query = nil
        comps?.fragment = nil
        return comps?.url ?? self
    }
}

/// 셀 렌더링용 결과(이미지/영상별 썸네일/로컬URL 포함)
public enum CellRenderable {
    case photo(image: UIImage, originalURL: String)
    case video(thumbnail: UIImage, localURL: URL, originalURL: String)
}

/// 다운로드+저장 전체를 조합하는 오케스트레이터
public final class MediaSaver {

    public static let shared = MediaSaver()
    private init() {}

    /// 단일 미디어를 셀 렌더링용으로 받기 (이미지 or 비디오썸네일)
    /// 반환값: 취소 가능한 URLSessionDataTask (비디오의 경우 실제 네트워크 태스크)
    
    @discardableResult
    func loadRenderable(for media: Media, completion: @escaping (CellRenderable?) -> Void) -> URLSessionDataTask? {
        switch media {
        case .image(let urlString):
            return MediaDownloader.shared.loadImage(urlString) { image in
                guard let image else { completion(nil); return }
                completion(.photo(image: image, originalURL: urlString))
            }
        case .video(let urlString):
            return MediaDownloader.shared.loadVideo(urlString) { localUrl in
                guard let localUrl else { completion(nil); return }
                let videoCellRenderable = Self.makeVideoThumbnail(from: localUrl).map { CellRenderable.video(thumbnail: $0, localURL: localUrl, originalURL: urlString) }
                completion(videoCellRenderable)
            }
        }
    }
    
    // MARK: - Public High-level APIs

    public func downloadAndSaveMedia(_ item: Media,
                                     imageFormat: SaveImageFormat,
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        self.downloadAndSaveMedias([item], imageFormat: imageFormat, completion: completion)
    }
    /// 여러 개(이미지만/비디오만/혼합 모두) 순차 저장
    public func downloadAndSaveMedias(_ items: [Media],
                                     imageFormat: SaveImageFormat,
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        func step(_ idx: Int) {
            if idx >= items.count { completion(.success(())); return }
            
            switch items[idx] {
            case .image(let url):
                MediaDownloader.shared.loadImage(url) { img in
                    Logger.log("url:\(url), img:\(String(describing: img))")
                    guard let img else { completion(.failure(PhotoAlbumHelperError.dataEncodingFailed)); return }
                    PhotoAlbumHelper.shared.saveImageToInstaDownload(img, format: imageFormat) { res in
                        switch res {
                        case .success: step(idx + 1)
                        case .failure(let e): completion(.failure(e))
                        }
                    }
                }
                
            case .video(let url):
                MediaDownloader.shared.loadVideo(url) { local in
                    guard let local else { completion(.failure(PhotoAlbumHelperError.fileNotReachable)); return }
                    PhotoAlbumHelper.shared.saveVideoToInstaDownload(local) { res in
                        switch res {
                        case .success: step(idx + 1)
                        case .failure(let e): completion(.failure(e))
                        }
                    }
                }
            }
        }
        step(0)
    }

    // MARK: - 썸네일 생성 (첫 프레임)
    private static func makeVideoThumbnail(from fileURL: URL, at seconds: Double = 0.0) -> UIImage? {
        let asset = AVURLAsset(url: fileURL)
        let gen   = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 1024, height: 1024) // 과한 메모리 사용 방지

        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        do {
            let cg = try gen.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cg)
        } catch {
            return nil
        }
    }
}
