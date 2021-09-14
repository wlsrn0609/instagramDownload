# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'InstagramDownload' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  platform :ios, '11.0'
  
  #https://github.com/Alamofire/Alamofire
  pod 'Alamofire', '~> 4.7'
  
  #https://github.com/thii/FontAwesome.swift
  pod 'FontAwesome.swift', '1.9.1'
  
  #https://github.com/SDWebImage/SDWebImage
  pod 'SDWebImage', '~> 4.0'
  pod 'SDWebImage/GIF', '4.4.8'

  #https://github.com/evgenyneu/keychain-swift
  pod 'KeychainSwift', '~> 13.0'

  #https://github.com/ReactiveX/RxSwift
  pod 'RxSwift', '5.1.1'
  pod 'RxCocoa', '5.1.1'
  pod 'RxDataSources', '4.0.1'
  
  #https://github.com/jdg/MBProgressHUD
  pod 'MBProgressHUD', '~> 1.2.0'

  ##https://github.com/devxoul/Toaster
  pod 'Toaster', '2.3.0'

  #https://github.com/davbeck/TUSafariActivity
  pod 'TUSafariActivity', '~> 1.0'
  
  #https://github.com/SnapKit/SnapKit
  pod 'SnapKit', '~> 5.0.0'

  #https://github.com/devxoul/Then
  pod 'Then', '2.7.0'
  
  #https://github.com/RxSwiftCommunity/NSObject-Rx
  pod 'NSObject+Rx', '5.1.0'

  #https://github.com/RxSwiftCommunity/RxAlamofire
  pod 'RxAlamofire', '5.1.0'
  
  
end
