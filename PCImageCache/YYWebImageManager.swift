//
//  YYWebImageManager.swift
//  PCImageCache
//
//  Created by tangyuhua on 2017/6/1.
//  Copyright © 2017年 tangyuhua. All rights reserved.
//

import Foundation

private var networkIndicatorInfoKey: Void?

struct YYWebImageApplicationNetworkIndicatorInfo {
    var count: Int = 0
    var timer: Timer!
}





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

enum  YYWebImageFromType {
    case none, memoryCacheFast,memoryCache,diskCache,remote
}

enum YYWebImageStage {
    case progress
    case cancelled
    case finished
}

typealias YYWebImageProgressBlock = (Int,Int) -> Void

typealias YYWebImageTransformBlock = (UIImage, URL) -> UIImage?

typealias YYWebImageCompletionBlock = (UIImage?, URL, YYWebImageFromType, YYWebImageStage) throws -> Void


class YYWebImageManager {
    var cache: YYImageCache
    var queue: OperationQueue?
    var sharedTransformBlock: YYWebImageTransformBlock?
    var timeout: TimeInterval
    var username: String? = nil
    var password: String? = nil
    var headers: [String:String]?
    var headersFilter :((URL, [String:String]?) -> [String: String])?
    var cacheKeyFilter :((URL) -> String)? = nil
    
    public static let shared:YYWebImageManager = {
       let cache = YYImageCache.shared
       var  queue = OperationQueue.current
       queue?.qualityOfService = .background
        return YYWebImageManager(withCache: cache, queue: queue!)
    }()
    
    init(withCache cache:YYImageCache, queue que:OperationQueue) {
        self.cache = cache
        self.queue = que
        self.timeout = 15.0
        if YYImageWebPAvailable() {
            headers = ["Accept" : "image/webp,image/*;q=0.8"]
        } else {
            headers = ["Accept" : "image/*;q=0.8" ];
        }
        
    }
    init() {
        fatalError("YYWebImageManager init error -- Use the designated initializer to init")
       
    }
    
    func requestImage(with url:URL,
                      options opt :YYWebImageOptions,
                      progress pro:YYWebImageProgressBlock?,
                      transform trans: YYWebImageTransformBlock?,completion comp: YYWebImageCompletionBlock?) -> YYWebImageOperation {
        var request = URLRequest(url: url)
        request.timeoutInterval = self.timeout
        request.httpShouldHandleCookies = opt.contains(.handleCookies)
        request.allHTTPHeaderFields = headersFor(URL: url)
        request.httpShouldUsePipelining = true
        
        if opt.contains(.useNSURLCache) {
             request.cachePolicy =   .useProtocolCachePolicy
        } else {
            request.cachePolicy  =    .reloadIgnoringLocalCacheData
        }
        
        let operation = YYWebImageOperation(with: request, options: opt, cache: self.cache, cacheKey: cacheKeyFor(URL: url), progress: pro, transform: trans , completion: comp)
        
        if username != nil , password != nil  {
            operation.credential = URLCredential(user: username!, password: password!, persistence: URLCredential.Persistence.forSession)
        }
        
        if self.queue != nil {
            self.queue!.addOperation(operation)
        } else {
            operation.start()
        }
        return operation
        
    }
    
    func headersFor(URL url:URL) -> [String: String]? {
        if self.headersFilter != nil {
            return self.headersFilter!(url, self.headers)
        } else {
            return self.headers
        }
        
    }
    
    func cacheKeyFor(URL url:URL) -> String {
        if self.cacheKeyFilter != nil {
            return self.cacheKeyFilter!(url)
        } else {
            return url.absoluteString
        }
    }
   

    


     // MARK: - Network Indicator
    

    static func YYSharedApplication() -> UIApplication? {
        return  nil
    }

    static var  networkIndicatorInfo:YYWebImageApplicationNetworkIndicatorInfo? {
        get {
            return objc_getAssociatedObject(self, &networkIndicatorInfoKey) as? YYWebImageApplicationNetworkIndicatorInfo
        }
        set {
            objc_setAssociatedObject(self, &networkIndicatorInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    @objc static func delaySetActivity(_ timer: Timer) {
        guard let  app = YYWebImageManager.YYSharedApplication() else {return}
        let  visiable = timer.userInfo as! Bool
        if app.isNetworkActivityIndicatorVisible != visiable {
            app.isNetworkActivityIndicatorVisible = true
        }
        timer.invalidate()
    }

   
    static func  changeNetworkActivityCount(delta: Int) {
        guard let  _ = YYWebImageManager.YYSharedApplication() else {
            return
        }
        
        let block: ()->() = {
            var  info: YYWebImageApplicationNetworkIndicatorInfo!  =  networkIndicatorInfo;
            if  info == nil  {
                info = YYWebImageApplicationNetworkIndicatorInfo();
                YYWebImageManager.networkIndicatorInfo = info;
            }
        var  count = info.count
        count += delta
        info.count = count
        info.timer.invalidate()
        info.timer = Timer(timeInterval: (1 / 3.0), target: self, selector: #selector(delaySetActivity), userInfo: (info.count > 0), repeats: true)
           
        RunLoop.main.add(info.timer, forMode: .commonModes)
        };
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
               block()
            }
        }
    }
    
    static func incrementNetworkActivityCount() {
        changeNetworkActivityCount(delta: 1)
    }
    
    static func decrementNetworkActivityCount(){
        changeNetworkActivityCount(delta: -1)
    }
    
    static func currentNetworkActivityCount() -> Int {
    let info = networkIndicatorInfo
    return info!.count;
    }

    
}
