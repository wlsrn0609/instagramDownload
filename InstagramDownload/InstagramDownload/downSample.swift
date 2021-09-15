//
//  downSample.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/15.
//

import UIKit

extension UIImage {
    
    func downSample( pointSize : CGSize, complete: @escaping ( (_ image : UIImage?) -> Void)) {
        let maxContentSize = max(self.size.width, self.size.height)
        let minimumPointSize = min(pointSize.width, pointSize.height)
        let scale = (minimumPointSize / maxContentSize) * UIScreen.main.scale
        
        let targetImage = self
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let targetSize = targetImage.size.applying(transform)
        UIGraphicsBeginImageContext(targetSize)
        targetImage.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let afterImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        complete(afterImage)
    }
   
}
