//
//  Extensions.swift
//  instaDownload
//
//  Created by 권진구 on 5/26/25.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(message: String, title: String = "알림") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
