//
//  YYWebImageManager.swift
//  PCImageCache
//
//  Created by tangyuhua on 2017/6/1.
//  Copyright © 2017年 tangyuhua. All rights reserved.
//

import Foundation


public struct YYWebImageOptions:OptionSet {
    public let rawValue: Int
    public static let showNetworkActivit    = YYWebImageOptions(rawValue: 1 << 0)
    
    public static let progressive           = YYWebImageOptions(rawValue: 1 << 1)
    
    public static let progressiveBlur       = YYWebImageOptions(rawValue: 1 << 2)
    
    public static let useNSURLCache         = YYWebImageOptions(rawValue: 1 << 3)
    
    public static let invalidSSL            = YYWebImageOptions(rawValue: 1 << 4)
    
    public static let backgroundTask        = YYWebImageOptions(rawValue: 1 << 5)
    
    public static let handleCookies         = YYWebImageOptions(rawValue: 1 << 6)
    
    public static let refreshImageCache     = YYWebImageOptions(rawValue: 1 << 7)
    
    public static let ignoreDiskCache       = YYWebImageOptions(rawValue: 1 << 8)
    
    public static let ignorePlaceHolder     = YYWebImageOptions(rawValue: 1 << 9)
    
    public static let ignoreImageDecoding   = YYWebImageOptions(rawValue: 1 << 10)
    
    public static let ignoreAnimatedImage   = YYWebImageOptions(rawValue: 1 << 11)
    
    public static let setImageWithFadeAnimation = YYWebImageOptions(rawValue: 1 << 12)
    
    public static let avoidSetImage = YYWebImageOptions(rawValue: 1 << 13)
    
    public static let ignoreFailedUR = YYWebImageOptions(rawValue: 1 << 14)
   
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
