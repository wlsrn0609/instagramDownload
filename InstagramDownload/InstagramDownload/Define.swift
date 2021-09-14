import UIKit
import KeychainSwift

var APP_NAME : String {
    get{
        if let infoDic = Bundle.main.infoDictionary,
            let name = infoDic["CFBundleDisplayName"] as? String{
            return name
        }
        return ""
    }
}


let DEVICE_ID  = "DEVICE_ID"
let deviceID : String = {
    print("get deviceID================================================================")
    
    if let kDeviceID = userD.string(forKey: DEVICE_ID) {
        print("userD에 DeviceID가 있으면 사용 : \(kDeviceID)")
        return kDeviceID
    }else if let kDeviceID = KeychainSwift().get(DEVICE_ID) {
        print("userD에 없으면(앱이 삭제) -> 키체인에서 조회 -> 있으면 UserD에 저장후 리턴:\(kDeviceID)")
        
        userD.set(kDeviceID, forKey: DEVICE_ID)
        userD.synchronize()
        
        return kDeviceID
    }else{
        print("userD,키체인 모두 없으면 -> 앱 처음시작 -> 새로 생성 후 키체인 및 userD에 저장후 리턴")
        
        let kDeviceID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        
        KeychainSwift().set(kDeviceID, forKey: DEVICE_ID, withAccess: .accessibleAlways)
        
        userD.set(kDeviceID, forKey: DEVICE_ID)
        userD.synchronize()
        
        print("kDeviceID:\(kDeviceID)")
        return kDeviceID
    }
}()

let appDel = (UIApplication.shared.delegate as! AppDelegate)
let userD = UserDefaults.standard

struct SCREEN {
    static var WIDTH : CGFloat {
        min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    }
    static var HEIGHT : CGFloat {
        max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    }
}

var STATUS_BAR_HEIGHT : CGFloat {
    if let value = appDel.window?.safeAreaInsets.top {
        print("read top SafeArea : window is not nil \(value)")
        return value
    }else{
        print("read top SafeArea : window is nil")
        return IS_NORCH ? 44 : 20
    }
}
var NAVIGATION_BAR_HEIGHT : CGFloat {
    get{
        return UINavigationController().navigationBar.frame.size.height
    }
}
let TABBAR_HEIGHT         : CGFloat = 49

let MY_IPHONE : CGFloat = {
    return max(SCREEN.WIDTH, SCREEN.HEIGHT)
}()

let MY_IPAD : CGFloat = {
    return max(SCREEN.WIDTH, SCREEN.HEIGHT)
}()

let IS_PHONE = UIDevice.current.userInterfaceIdiom == .phone
let IS_PAD   = UIDevice.current.userInterfaceIdiom == .pad

let IPAD_NORMAL : CGFloat   = 1024 // 1024 x 768 * 2  = 2048 x 1536 - 1.333
let IPAD_PRO_10_1 : CGFloat = 1112 // 1112 x 834 * 2  = 2224 * 1668 - 1.333
let IPAD_PRO_11 : CGFloat   = 1194 // 1194 x 834 * 2  = 2388 x 1668 - 1.431
let IPAD_PRO_12_9 : CGFloat = 1366 // 1366 x 1024 * 2 = 2732 x 2048 - 1.333

let IS_ROUNDED_IPAD : Bool = {
    return IS_PAD && STATUS_BAR_HEIGHT == 24
}()
//let IS_NORCH : Bool = {
//    return IS_PHONE && STATUS_BAR_HEIGHT == 44
//}()
let IS_NORCH : Bool = {
    
    let maxWidth = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    let minWidth = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    
    let ratio = maxWidth / minWidth
    
    print("ratio : \(ratio)")
//    norch : 2.16
//    non norch : 1.7
    
    return ratio > 2
    
//    return IS_PHONE && STATUS_BAR_HEIGHT == 44
}()

let IPHONE_SE : CGFloat        = 568 // 320 x 568 * 2 - 0.5633
let IPHONE_N : CGFloat         = 667 // 375 x 667 * 2 - 0.5622
let IPHONE_N_PLUS : CGFloat    = 736 // 414 x 736 * 3 - 0.5625

let IPHONE_X : CGFloat         = 812 // 375 x 812 * 3 - 0.4618
let IPHONE_XR : CGFloat        = 896 // 414 x 896 * 2 - 0.4620
let IPHONE_MAX : CGFloat       = 896 // 414 x 896 * 3 - 0.4620
let IPHONE_12PRO : CGFloat     = 844 // 390 x 844 * 3 - 0.4620
let IPHONE_12PRO_MAX : CGFloat = 926 // 428 x 926 * 3 - 0.4622

let IPHONE_12MINI_ZOOM : CGFloat = 693 // 320 x 693 * 3 - 0.4617
let IPHONE_12_ZOOM : CGFloat = 693 // 320 x 693 * 3 - 0.4617

let IS_IPHONE_SE               = (MY_IPHONE == IPHONE_SE)
let IS_IPHONE_N                = (MY_IPHONE == IPHONE_N)
let IS_IPHONE_N_PLUS           = (MY_IPHONE == IPHONE_N_PLUS)
let IS_IPHONE_X                = (MY_IPHONE == IPHONE_X)
let IS_IPHONE_XR               = (MY_IPHONE == IPHONE_XR)
let IS_IPHONE_MAX              = (MY_IPHONE == IPHONE_MAX)
let IS_IPHONE_12PRO            = (MY_IPHONE == IPHONE_12PRO)
let IS_IPHONE_12PRO_MAX        = (MY_IPHONE == IPHONE_12PRO_MAX)

let IS_IPHONE_12MINI_ZOOM  = (MY_IPHONE == IPHONE_12MINI_ZOOM)
let IS_IPHONE_12_ZOOM  = (MY_IPHONE == IPHONE_12_ZOOM)
 
//let SAFE_AREA : CGFloat = {
//    IS_NORCH ? 44 : 0
//}()
var SAFE_AREA : CGFloat {
    if let value = appDel.window?.safeAreaInsets.bottom {
        print("read bottom SafeArea : window is not nil \(value)")
        return value
    }else{
        print("read bottom SafeArea : window is nil")
        return IS_NORCH ? 34 : 0
    }
}
var SAFE_AREA_SIDE : CGFloat {
    get{
        return IS_NORCH ? 44 : 0
    }
}
let BOTTOM_SAFE_AREA : CGFloat = {
    IS_NORCH ? 20 : 0
}()


let AppleSDGothicNeo                   = "Apple SD Gothic Neo"
let AppleSDGothicNeoBold               = "Apple SD Gothic Neo Bold"
let NanumGothicOTF                     = "NanumGothicOTF"
let NanumGothicOTFBold                 = "NanumGothicOTFBold"

let Arita_dotum_Bold_OTF               = "Arita-dotum-Bold_OTF"
let Arita_dotum_Light_OTF              = "Arita-dotum-Light_OTF"
let Arita_dotum_Medium_OTF             = "Arita-dotum-Medium_OTF"
let Arita_dotum_SemiBold_OTF           = "Arita-dotum-SemiBold_OTF"
let Arita_dotum_Thin_OTF               = "Arita-dotum-Thin_OTF"

let Nanum_Barun_Gothic_OTF             = "NanumBarunGothicOTF"
let Nanum_Barun_Gothic_OTF_Ultra_Light = "NanumBarunGothicOTFUltraLight"
let Nanum_Barun_Gothic_OTF_Light       = "NanumBarunGothicOTFLight"
let Nanum_Barun_Gothic_OTF_Bold        = "NanumBarunGothicOTFBold"

let ROBOTO_REGULAR                     = "Roboto-Regular"
let ROBOTO_BLACK                       = "Roboto-Black"
let ROBOTO_LIGHT                       = "Roboto-Light"
let ROBOTO_BOLD_ITALIC                 = "Roboto-BoldItalic"
let ROBOTO_LIGHT_ITALIC                = "Roboto-LightItalic"
let ROBOTO_THIN                        = "Roboto-Thin"
let ROBOTO_MEDUM_ITALIC                = "Roboto-MediumItalic"
let ROBOTO_MEDIUM                      = "Roboto-Medium"
let ROBOTO_BOLD                        = "Roboto-Bold"
let ROBOTO_BLACK_ITALIC                = "Roboto-BlackItalic"
let ROBOTO_ITALIC                      = "Roboto-Italic"
let ROBOTO_THIN_ITALIC                 = "Roboto-ThinItalic"

let SFMono_Heavy                       = "SFMono-Heavy"
let SFMono_Medium                      = "SFMono-Medium"
let SFMono_Regular                     = "SFMono-Regular"
let SFMono_Bold                        = "SFMono-Bold"
let SFMono_MediumItalic                = "SFMono-MediumItalic"
let SFMono_SemiboldItalic              = "SFMono-SemiboldItalic"
let SFMono_Light                       = "SFMono-Light"
let SFMono_Semibold                    = "SFMono-Semibold"
let SFMono_RegularItalic               = "SFMono-RegularItalic"
let SFMono_BoldItalic                  = "SFMono-BoldItalic"
let SFMono_HeavyItalic                 = "SFMono-HeavyItalic"
let SFMono_LightItalic                 = "SFMono-LightItalic"

let MyriadPro_Bold                     = "MyriadPro-Bold"

let Muli_ExtraBoldItalic               = "Muli-ExtraBoldItalic"
let Muli_ExtraBold                     = "Muli-ExtraBold"
let Muli_Italic                        = "Muli-Italic"
let Muli_BoldItalic                    = "Muli-BoldItalic"
let Muli_Regular                       = "Muli-Regular"
let Muli_Bold                          = "Muli-Bold"
let Muli_SemiBold                      = "Muli-SemiBold"
let Muli_SemiBoldItalic                = "Muli-SemiBoldItalic"
let Muli_Black                         = "Muli-Black"
let Muli_BlackItalic                   = "Muli-BlackItalic"
let Muli_ExtraLight                    = "Muli-ExtraLight"
let Muli_ExtraLightItalic              = "Muli-ExtraLightItalic"
let Muli_Light                         = "Muli-Light"
let Muli_LightItalic                   = "Muli-LightItalic"

let DINPro_Black                       = "DINPro-Black"
let DINPro_Medium                      = "DINPro-Medium"
let DINPro_CondensedRegular            = "DINPro-CondensedRegular"
let DINPro_CondensedLight              = "DINPro-CondensedLight"
let DINPro_CondensedMediumItalic       = "DINPro-CondensedMediumItalic"
let DINPro_Light                       = "DINPro-Light"
let DINPro_Italic                      = "DINPro-Italic"
let DINPro_BlackItalic                 = "DINPro-BlackItalic"
let DINPro_BoldItalic                  = "DINPro-BoldItalic"
let DINPro                             = "DINPro"
let DINPro_CondensedMedium             = "DINPro-CondensedMedium"
let DINPro_CondensedLightItalic        = "DINPro-CondensedLightItalic"
let DINPro_CondensedBlackItalic        = "DINPro-CondensedBlackItalic"
let DINPro_CondensedBold               = "DINPro-CondensedBold"
let DINPro_CondensedItalic             = "DINPro-CondensedItalic"
let DINPro_CondensedBoldItalic         = "DINPro-CondensedBoldItalic"
let DINPro_MediumItalic                = "DINPro-MediumItalic"
let DINPro_CondensedBlack              = "DINPro-CondensedBlack"
let DINPro_LightItalic                 = "DINPro-LightItalic"
let DINCondensed_Bold                  = "DINCondensed-Bold"
let DINAlternate_Bold                  = "DINAlternate-Bold"


let NanumSquareEB                      = "NanumSquareEB"
let NanumSquareL                       = "NanumSquareL"
let NanumSquareB                       = "NanumSquareB"
let NanumSquareR                       = "NanumSquareR"
let NanumSquareRoundEB                 = "NanumSquareRoundEB"
let NanumSquareRoundL                  = "NanumSquareRoundL"
let NanumSquareRoundB                  = "NanumSquareRoundB"
let NanumSquareRoundR                  = "NanumSquareRoundR"

let TimesNewRomanPS_ItalicMT           = "TimesNewRomanPS-ItalicMT"
let TimesNewRomanPS_BoldItalicMT       = "TimesNewRomanPS-BoldItalicMT"
let TimesNewRomanPS_BoldMT             = "TimesNewRomanPS-BoldMT"
let TimesNewRomanPSMT                  = "TimesNewRomanPSMT"


let HelveticaNeue_UltraLightItalic     = "HelveticaNeue-UltraLightItalic"
let HelveticaNeue_Medium               = "HelveticaNeue-Medium"
let HelveticaNeue_MediumItalic         = "HelveticaNeue-MediumItalic"
let HelveticaNeue_UltraLight           = "HelveticaNeue-UltraLight"
let HelveticaNeue_Italic               = "HelveticaNeue-Italic"
let HelveticaNeue_Light                = "HelveticaNeue-Light"
let HelveticaNeue_ThinItalic           = "HelveticaNeue-ThinItalic"
let HelveticaNeue_LightItalic          = "HelveticaNeue-LightItalic"
let HelveticaNeue_Bold                 = "HelveticaNeue-Bold"
let HelveticaNeue_Thin                 = "HelveticaNeue-Thin"
let HelveticaNeue_CondensedBlack       = "HelveticaNeue-CondensedBlack"
let HelveticaNeue                      = "HelveticaNeue"
let HelveticaNeue_CondensedBold        = "HelveticaNeue-CondensedBold"
let HelveticaNeue_BoldItalic           = "HelveticaNeue-BoldItalic"

let Dinmed                             = "Dinmed"

let NotoSansCJKkr_Black                = "NotoSansCJKkr-Black"
let NotoSansCJKkr_Bold                 = "NotoSansCJKkr-Bold"
let NotoSansCJKkr_Thin                 = "NotoSansCJKkr-Thin"
let NotoSansCJKkr_Regular              = "NotoSansCJKkr-Regular"
let NotoSansCJKkr_Light                = "NotoSansCJKkr-Light"
let NotoSansCJKkr_DemiLight            = "NotoSansCJKkr-DemiLight"
let NotoSansCJKkr_Medium               = "NotoSansCJKkr-Medium"

let OpenSans_Regular = "OpenSans-Regular"
let OpenSans_Light = "OpenSans-Light"
let OpenSans_LightItalic = "OpenSans-LightItalic"
let OpenSans_SemiBold = "OpenSans-SemiBold"
let OpenSans_SemiBoldItalic = "OpenSans-SemiBoldItalic"
let OpenSans_Bold = "OpenSans-Bold"
let OpenSans_BoldItalic = "OpenSans-BoldItalic"
let OpenSans_ExtraBold = "OpenSans-ExtraBold"
let OpenSans_Italic = "OpenSans-Italic"
