//
//  Extenstion.swift
//  InstagramDownload
//
//  Created by JinGu on 2021/09/17.
//

import UIKit
import MBProgressHUD

extension AppDelegate {
    //MARK:about MBProgressHUD
    
    struct MBProgressHUD_AssociatedKeys {
        static var MBProgressHUD: UInt8 = 0
    }
    
    var hud : MBProgressHUD? {
        get {
            guard let value = objc_getAssociatedObject(self, &MBProgressHUD_AssociatedKeys.MBProgressHUD) as? MBProgressHUD else { return nil }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &MBProgressHUD_AssociatedKeys.MBProgressHUD, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func showHud(){
        DispatchQueue.main.async {
            self.hud?.hide(animated: false)
            self.hud = MBProgressHUD.showAdded(to: self.window!, animated: true)
            if #available(iOS 13.0, *) {
                self.hud?.overrideUserInterfaceStyle = .dark
            }
        }
        
    }
    
    public func hideHud(animated : Bool = true){
        DispatchQueue.main.async {
            self.hud?.hide(animated: animated)
        }
    }
    
}
