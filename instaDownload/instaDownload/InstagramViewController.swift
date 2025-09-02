//  InstagramViewController.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.

import UIKit
@preconcurrency import WebKit

class InstagramViewController: UIViewController {

    var webView: WKWebView!
    let downloadButton = UIButton(type: .system)
    var blockingView: UIView?
    var urls: [String] = []

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
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        ])
    }

    func setupButtons() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 10

        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("🔄", for: .normal)
        refreshButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        refreshButton.backgroundColor = .lightGray
        refreshButton.tintColor = .white
        refreshButton.layer.cornerRadius = 8
        refreshButton.addTarget(self, action: #selector(refreshClipboardURL), for: .touchUpInside)

        downloadButton.setTitle("다운로드", for: .normal)
        downloadButton.backgroundColor = .systemBlue
        downloadButton.tintColor = .white
        downloadButton.layer.cornerRadius = 8
        downloadButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)

        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("설정", for: .normal)
        settingsButton.backgroundColor = .darkGray
        settingsButton.tintColor = .white
        settingsButton.layer.cornerRadius = 8
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        stack.addArrangedSubview(refreshButton)
        stack.addArrangedSubview(downloadButton)
        stack.addArrangedSubview(settingsButton)

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.widthAnchor.constraint(equalToConstant: 360),
            stack.heightAnchor.constraint(equalToConstant: 44),
            webView.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -10)
        ])
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
        urls.removeAll()
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
        webView.evaluateJavaScript(JSCode.goToMoveFirst) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.collectSequentially(attempt: 0)
            }
        }
    }

    func collectSequentially(attempt: Int) {
        guard attempt < 100 else {
            self.presentMediaList()
            return
        }

        webView.evaluateJavaScript(JSCode.getMedia) { result, _ in
            if let url = result as? String, self.urls.last != url {
                self.urls.append(url)
            }

            self.webView.evaluateJavaScript(JSCode.gotoNext) { clickedResult, _ in
                let clicked = clickedResult as? Bool ?? false

                if clicked {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.collectSequentially(attempt: attempt + 1)
                    }
                } else {
                    let clipboardURL = UIPasteboard.general.string ?? ""
                    let postId = self.extractPostId(from: clipboardURL) ?? ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.webView.evaluateJavaScript(JSCode.collectAllJSForLastItem(postId: postId)) { result, _ in
                            if let urls = result as? [String] {
                                for url in urls where !self.urls.contains(url) {
                                    self.urls.append(url)
                                }
                            }
                            self.presentMediaList()
                        }
                    }
                }
            }
        }
    }

    func presentMediaList() {
        hideBlockingView()

        let items = urls.map { url -> MediaItem in
            let type: MediaType = url.contains(".mp4") ? .video : .image
            return MediaItem(url: url, previewURL: "", type: type)
        }

        if items.isEmpty {
            showAlert(message: "미디어를 찾을 수 없습니다")
        } else {
            let listVC = MediaListViewController(mediaItems: items)
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
