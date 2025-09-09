//  InstagramViewController.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.

import UIKit
@preconcurrency import WebKit

class InstagramViewController: UIViewController {

    @IBOutlet weak var backView: UIView!
    var webView: WKWebView!
    
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    var blockingView: UIView?
    var medias: [Media] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupButtons()
        loadInstagram()
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        backView.addSubview(webView)
        
        backView.clipsToBounds = true
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 0),
            webView.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 0),
            webView.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: 0),
            webView.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: 0),
        ])
        
        backView.backgroundColor = UIColor.clear
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backView.layer.cornerRadius = 20
        [refreshButton,downloadButton,settingsButton].forEach { $0?.layer.cornerRadius = 20 }
    }

    
    func setupButtons() {
        refreshButton.addTarget(self, action: #selector(refreshClipboardURL), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        stack.backgroundColor = UIColor.clear
        
    }

    func loadInstagram() {
        let clipboardURL = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.log("clipboardURL:\(clipboardURL)")
        
        if let clipboardURL, clipboardURL.contains("instagram.com/"),
           let url = URL(string: clipboardURL) {
            webView.load(URLRequest(url: url))
        } else if let url = URL(string: "https://www.instagram.com/") {
            webView.load(URLRequest(url: url))
        }
    }

    @objc func refreshClipboardURL() {
        loadInstagram()
    }

    @objc func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @objc func handleDownload() {
        guard blockingView == nil else { return }

        guard let clipboardURL = UIPasteboard.general.string,
              clipboardURL.contains("instagram.com/") else {
            showAlert(message: "올바른 인스타그램 게시물 링크가 아닙니다.")
            return
        }

        showBlockingView()
        medias.removeAll()
        moveToFirstSlideAndStartCollection()
    }

    func extractPostId(from url: String) -> String? {
        guard let range = url.range(of: "/p/") else { return nil }
        let substring = url[range.upperBound...]
        if let end = substring.firstIndex(of: "/") {
            return String(substring[..<end])
        } else {
            return String(substring)
        }
    }

    func moveToFirstSlideAndStartCollection() {
        
        if let clipboardURL = UIPasteboard.general.string,
           clipboardURL.contains("instagram.com"),
           clipboardURL.contains("/stories/") {
            Logger.log()
            collectStoryOnce()
            return
        }
        
        webView.evaluateJavaScript(JSCode.goToMoveFirst) { [weak self] _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.collectSequentially(attempt: 0)
            }
        }
    }
    
    func collectStoryOnce(){
        webView.evaluateJavaScript(JSCode.getStoryMedia) { [weak self] result, _ in
            guard let self = self else { return }
            Logger.log("result : \(result)")
            if let s = result as? String {
                let items = s
                    .split(separator: ",")
                    .map { String($0) }
                    .map(self.guessMedia(from:))
                // 중복 제거
                for item in items where !self.medias.contains(where: { $0.canonicalKey == item.canonicalKey }) {
                    self.medias.append(item)
                }
            } else {
                // 혹시 형식이 달라도 방어적으로 기존 파서 사용
                let items = self.parseJSGetMediaResult(result)
                for item in items where !self.medias.contains(where: { $0.canonicalKey == item.canonicalKey }) {
                    self.medias.append(item)
                }
            }
            
            // 바로 종료/표시
            self.presentMediaList()
        }
    }

    func collectSequentially(attempt: Int) {
        guard attempt < 100 else {
            self.presentMediaList()
            return
        }

        webView.evaluateJavaScript(JSCode.getMedia) { [weak self] result, _ in
            guard let self else { return }
            
            guard let resultString = result as? String else { return }
            let items = resultString.split(separator: ",")
                .map { String($0)}
                .compactMap { [weak self] in self?.guessMedia(from: $0) }

            // ❶ 이번 슬라이드에서 아무것도 못 얻었으면, 다음으로 넘어가지 말고 같은 슬라이드 재시도
            if items.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.collectSequentially(attempt: attempt + 1)
                }
                return
            }

            // ❷ 얻은 아이템을 중복 제거 후 추가 (아래 canonicalKey 참고)
            for item in items where !self.medias.contains(where: { $0.canonicalKey == item.canonicalKey }) {
                self.medias.append(item)
            }

            // ❸ 그 다음에야 다음 슬라이드로 이동
            self.webView.evaluateJavaScript(JSCode.gotoNext) { [weak self] clickedResult, _ in
                guard let self else { return }
                let clicked = clickedResult as? Bool ?? false

                if clicked {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        self.collectSequentially(attempt: attempt + 1)
                    }
                } else {
                    // 마지막 슬라이드: 보강 수집 로직 유지
                    let clipboardURL = UIPasteboard.general.string ?? ""
                    let postId = self.extractPostId(from: clipboardURL) ?? ""

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.webView.evaluateJavaScript(JSCode.collectAllJSForLastItem(postId: postId)) { [weak self] result, _ in
                            guard let self else { return }
                            let more = self.parseJSGetMediaResult(result)
                            for item in more where !self.medias.contains(where: { $0.canonicalKey == item.canonicalKey }) {
                                self.medias.append(item)
                            }
                            self.presentMediaList()
                        }
                    }
                }
            }
        }
    }

    private func parseJSGetMediaResult(_ result: Any?) -> [Media] {
        var out: [Media] = []

        // ① 레거시: result가 String 하나 (video 우선/이미지 1개만 반환하던 버전)
        if let s = result as? String {
            out.append(guessMedia(from: s))
            return out
        }

        // ② 배열(String)인 경우
        if let arr = result as? [String] {
            for s in arr { out.append(guessMedia(from: s)) }
            return out
        }

        // ③ 배열(딕셔너리)인 경우: [{type:"image"|"video", url:"..."}]
        if let arr = result as? [Any] {
            for any in arr {
                if let d = any as? [String: Any],
                   let type = d["type"] as? String,
                   let url = d["url"] as? String {
                    if type == "video" {
                        out.append(.video(urlString: url))
                    } else {
                        out.append(.image(urlString: url))
                    }
                } else if let s = any as? String { // 혹시 섞여 들어오면 방어
                    out.append(guessMedia(from: s))
                }
            }
            return out
        }

        return out
    }

    /// 확장자/경로로 대충 타입 유추 (JS가 type 안 줄 때 대비)
    private func guessMedia(from url: String) -> Media {
        let lower = url.lowercased()

            // 1) URL 파싱해서 pathExtension으로 확실하게 판별
            if let ext = URL(string: lower)?.pathExtension, ["mp4", "mov", "m4v"].contains(ext) {
                return .video(urlString: url)
            }

            // 2) 보조 휴리스틱 (릴스, dash 스트림 흔적 등)
            if lower.contains("/reel/") ||
               lower.contains("video_dash") ||
               lower.contains("is_video=1") {
                return .video(urlString: url)
            }

            return .image(urlString: url)
    }
    
    func presentMediaList() {
        hideBlockingView()

        if medias.isEmpty {
            showAlert(message: "미디어를 찾을 수 없습니다")
        } else {
            let listVC = MediaListViewController(medias: medias)
            self.present(UINavigationController(rootViewController: listVC), animated: true)
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

//MARK: BlockingView
extension InstagramViewController {
    func showBlockingView() {
        let blocker = UIView()
        blocker.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        blocker.isUserInteractionEnabled = true
        blocker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blocker)
        view.bringSubviewToFront(blocker)

        NSLayoutConstraint.activate([
            blocker.topAnchor.constraint(equalTo: view.topAnchor),
            blocker.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blocker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blocker.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        blockingView = blocker
    }

    func hideBlockingView() {
        blockingView?.removeFromSuperview()
        blockingView = nil
    }
}
