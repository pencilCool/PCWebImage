//
//  PCImageCache.swift
//  PCImageCache
//
//  Created by tangyuhua on 2017/5/31.
//  Copyright © 2017年 tangyuhua. All rights reserved.
//

import Foundation

import UIKit


public struct YYImageCacheType:OptionSet {
    public let rawValue: Int
    public static let none    = YYImageCacheType(rawValue: 1 << 0)
    public static let memory  = YYImageCacheType(rawValue: 1 << 0)
    public static let disk    =  YYImageCacheType(rawValue: 1 << 0)
    public static let all: YYImageCacheType = [.memory, .disk]
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

class YYImageCache {
    var name:String? = nil
    
    var memoryCache:YYMemoryCache? = nil
    var diskCache:YYDiskCache? = nil

    var allowAnimatedImage = true
    var decodeForDisplay = true
    
    public static var  sharedCache = YYImageCache(with: "hehda")
    
    init(with path:String ) {
        fatalError()
    }
    
    // 在后台执行，迅速返回
    func setImage(_ image:UIImage, forKey key:String) {
        fatalError()
    }
    
    func setImage(_ image:UIImage?, imageData data: Data?,
                  forKey key:String,with type:YYImageCacheType) {
        fatalError()
    }
    
    func removeImage(forKey key:String){
        fatalError()
    }
    
    func removeImage(forKey key:String, with type: YYImageCacheType){
        fatalError()
    }
    
    func containsImage(forKey key:String) -> Bool {
        fatalError()
        return false
    }
    
    func containsImage(forKey key:String, with type: YYImageCacheType) -> Bool {
        fatalError()
        return false
    }
    
    func getImage(forKey key:String) -> UIImage? {
        fatalError()
        return nil
    }
    
    func getImage(forKey key:String, with type: YYImageCacheType) -> UIImage? {
        fatalError()
        return nil
    }
    
    func getImage(forKey key:String, with type: YYImageCacheType, with block:(UIImage?,YYImageCacheType)-> Void) -> Data? {
        fatalError()
        return nil
    }
    
    func getImageData(forKey key: String) -> Data? {
        fatalError()
        return nil
    }
    
    func getImageData(forKey key: String, with block:(Data?)->Void)  {
        fatalError()
        return nil
    }
    
    
}
