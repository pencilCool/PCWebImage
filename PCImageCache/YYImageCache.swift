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
    var memoryCache:YYMemoryCache
    var diskCache:YYDiskCache

    var allowAnimatedImage = true
    var decodeForDisplay = true
    
    public static var sharedCache:YYImageCache {
        var cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        cachePath = cachePath.appending("com.pencilCool.yykit")
        let cache = YYImageCache(with: cachePath)
        return cache!
    }
    
    
    private lazy var YYImageCacheIOQueue: DispatchQueue = {
        return DispatchQueue.global(qos: .default)
    }()
    
    private lazy var YYImageCacheDecodeQueue: DispatchQueue = {
        return DispatchQueue.global(qos: .utility)
    }()
    
    
    
    init?(with path:String ) {
        guard  let dc = YYDiskCache(path: path) else {
            return nil
        }
        diskCache = dc
        diskCache.customArchiveBlock = {(obj) -> Data in
            return obj as! Data
        }
        
        diskCache.customUnarchiveBlock = { (data) -> Any in
            return data as Any
        }
        
        memoryCache  = YYMemoryCache()
        memoryCache.shouldRemoveAllObjectsOnMemoryWarning = true
        memoryCache.shouldRemoveAllObjectsWhenEnteringBackground = true
        memoryCache.countLimit = UInt.max
        memoryCache.costLimit = UInt.max
        memoryCache.ageLimit = 12 * 60 * 60
        
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
        
    }
    
    private func imageCost(_ image: UIImage) -> Int {
    
        guard let cgImage = image.cgImage else {
            return 1
        }
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow
        let cost = bytesPerRow * height
     
        guard cost == 0 else {
            return 1
        }
        return cost
    }
    
    private func image(from data: Data) -> UIImage {
        let scaleData = YYDiskCache.getExtendedData(from: data)
        var scale:CGFloat = 0.0
        if let scaleData = scaleData {
            scale = NSKeyedUnarchiver.unarchiveObject(with: scaleData) as! CGFloat
        }
        if scale <= 0 {scale = UIScreen.main.scale}
        var image: UIImage?
        if allowAnimatedImage {
            image = YYImage(data: data, scale: scale)!
            if decodeForDisplay {
                image = image?.yy_imageByDecoded()
            }
        } else {
            let decoder = YYImageDecoder(data: data, scale: scale)
            image = decoder?.frame(at: 0, decodeForDisplay: decodeForDisplay)?.image
        }
        return image!
    }
    
}

