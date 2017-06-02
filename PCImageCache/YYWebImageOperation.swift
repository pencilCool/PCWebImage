//
//  YYWebImageOperation.swift
//  PCImageCache
//
//  Created by tangyuhua on 2017/6/1.
//  Copyright © 2017年 tangyuhua. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    private static var onceToken = [String]()
    public class func once(_ token: String, _ block:@escaping () -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        if onceToken.contains(token) {
            return
        }
        onceToken.append(token)
        block()
    }
}




class YYWebImageOperation: Operation {
    
    public private(set) var request:URLRequest
    public private(set) var response:URLResponse?
    public private(set) var cache: YYImageCache?
    public private(set) var cacheKey: String
    public private(set) var options:YYWebImageOptions
    
    
    private var lock:NSRecursiveLock = NSRecursiveLock()
    private var connection: NSURLConnection!
    private var data: Data?
    private var expectedSize: Int = 0
    private var taskID: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    private var lastProgressiveDecodeTimestamp: TimeInterval = 0
    private var progressiveDecoder: YYImageDecoder?
    private var progressiveIgnored: Bool = false
    private var progressiveDetected: Bool = false
    private var progressiveScanedLength: UInt = 0
    private var progressiveDisplayCount: UInt = 0
    private var progress: YYWebImageProgressBlock?
    private var transform: YYWebImageTransformBlock?
    private var completion: YYWebImageCompletionBlock?
    
    
    private var _executing : Bool = false
    override var isExecuting : Bool {
        get { return _executing }
        set {
            guard _executing != newValue else { return }
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    
    private var _finished : Bool = false
    override var isFinished : Bool {
        get { return _finished }
        set {
            guard _finished != newValue else { return }
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    
    private  var _cancel: Bool = false
    override var isCancelled : Bool {
        get { return _cancel }
        set {
            guard _cancel != newValue else { return }
            willChangeValue(forKey: "isCancelled")
            _finished = newValue
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    



    

    
    var shouldUseCredentialStorage:Bool = true
    var credential: URLCredential?
    
    
     init(with request:URLRequest, options:YYWebImageOptions, cache:YYImageCache?,cacheKey: String?,progress:YYWebImageProgressBlock?, transform: YYWebImageTransformBlock?,completion: YYWebImageCompletionBlock?)
          {
            
            self.request = request
            self.options = options
            self.cache = cache
            self.cacheKey = cacheKey ?? request.url!.absoluteString
            self.progress = progress
            self.transform = transform
            self.completion = completion
            super.init()
    }
    
    deinit {
        self.lock.lock()
        if self.taskID != UIBackgroundTaskInvalid {
            YYShared.application()?.endBackgroundTask(self.taskID)
            self.taskID = UIBackgroundTaskInvalid
        }
        if self.isExecuting {
            self.isCancelled = true
            self.isFinished  = true
            if self.connection != nil {
                if !self.request.url!.isFileURL  && self.options.contains(.showNetworkActivit) {
                    YYWebImageManager.decrementNetworkActivityCount()
                }
            }
            
        if self.completion != nil {
                autoreleasepool {
                    do{
                        try self.completion!(nil, self.request.url!, .memoryCache, .cancelled)
                    } catch _ {}
                }
            }
            
        }
        self.lock.unlock()
        
    }
    
    func endBackgroundTask() {
        self.lock.lock()
        if self.taskID != UIBackgroundTaskInvalid {
            YYShared.application()?.endBackgroundTask(self.taskID)
            self.taskID = UIBackgroundTaskInvalid
        }
        
        self.lock.unlock()
    }
    
    private func finish() {
        self.isExecuting = false
        self.isFinished = false
        self.endBackgroundTask()
    }
    
    private static let networkThread:Thread = {
        let thread = Thread(target: self, selector: #selector(networkThreadMain), object: nil)
        return thread
    }()
    
    private func startOperation(){
        guard !self.isCancelled  else {
            return
        }
        autoreleasepool {
            if self.cache != nil && !self.options.contains(.useNSURLCache)
                && !self.options.contains(.refreshImageCache) {
                if let image = self.cache!.getImage(forKey: self.cacheKey, with: .memory) {
                    self.lock.lock()
                    if !self.isCancelled {
                        do {
                        try self.completion?(image,self.request.url!,.memoryCache, .finished)
                        } catch _ {}
                    }
                    self.lock.unlock()
                }
                
            }
            
            if !self.options.contains(.ignoreDiskCache) {
                imageQueue.async {
                    [weak self] in
                    if self == nil || self!.isCancelled {return}
                    if let image = self!.cache?.getImage(forKey: self!.cacheKey, with: .disk) {
                        self?.cache?.setImage(image, imageData: nil, forKey: self!.cacheKey, with: .memory)
                        self?.perform(#selector(YYWebImageOperation.didReceiveImageFromDiskCache(image:)), on:YYWebImageOperation.networkThread, with: image, waitUntilDone: false)
                    } else {
                        self?.perform(#selector(YYWebImageOperation.startRequest(_:)), on: YYWebImageOperation.networkThread, with: nil, waitUntilDone: false)
                    }
  
                } // async 
                
                
                return
                
            }
        }
        self.perform(#selector(startRequest(_:)), on: YYWebImageOperation.networkThread , with: nil, waitUntilDone: false)
        
    }
    
    @objc private func startRequest(_ object: Any) {
        if self.isCancelled {return}
        autoreleasepool{
            if self.options.contains(.ignoreFailedUR) &&
        }
    }
   
    
    @objc private static func networkThreadMain(object:Any) {
        autoreleasepool {
            Thread.current.name = "com.pencilCool.webimage.request"
            let runLoop = RunLoop.current
            runLoop.add(NSMachPort.port(withMachPort: 0), forMode: .defaultRunLoopMode)
        }
    }
    
    static var counter: Int32 = 0
    var imageQueue:DispatchQueue = {
        
        var queueCount = YYWebImageOperation.imageQueues.count;
        var cur: Int32 = Int32(OSAtomicIncrement32(&YYWebImageOperation.counter));
        cur = cur > 0 ?  cur : -cur;
        return YYWebImageOperation.imageQueues[Int(cur) % queueCount];
    }()
    
    static let   imageQueues : [DispatchQueue]  = {
        let maxQueueCount = 16
        var queueCount:Int = 0
        var queues : [DispatchQueue] = []
        queueCount = ProcessInfo.processInfo.activeProcessorCount
        queueCount = queueCount < 1 ? 1 : queueCount > maxQueueCount ? maxQueueCount:queueCount
            if #available(iOS 8.0, *) {
                for index in 0 ... queueCount {
                    let queue = DispatchQueue(label: "com.pencilCool.image.decode", qos: .utility)
                    queues.append(queue)
                }
            } else {
                // 可以不写了
                let queue = DispatchQueue(label: "com.pencilCool.image.decode", qos: .utility, target:DispatchQueue.global(qos: .utility))
                queues.append(queue)
        }
        return queues
    }()
    
    
    @objc private func didReceiveImageFromDiskCache(image: UIImage) {
        autoreleasepool{
            
        }
    }

}

// black list
private var URLBlacklistKey:UInt8 = 0
extension YYWebImageOperation {
    
    var URLBlacklist: NSMutableSet { // cat「实际上」是一个存储属性
        get {
            return associatedObject(base: self, key: &URLBlacklistKey)
            { return NSMutableSet() } // 设置变量的初始值
        }
        set { associateObject(base: self, key: &URLBlacklistKey, value: newValue) }
    }
    
    
    static dispatch_semaphore_t URLBlacklistLock;
    
    static void URLBlacklistInit() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    URLBlacklist = [NSMutableSet new];
    URLBlacklistLock = dispatch_semaphore_create(1);
    });
    }
    
    static BOOL URLBlackListContains(NSURL *url) {
    if (!url || url == (id)[NSNull null]) return NO;
    URLBlacklistInit();
    dispatch_semaphore_wait(URLBlacklistLock, DISPATCH_TIME_FOREVER);
    BOOL contains = [URLBlacklist containsObject:url];
    dispatch_semaphore_signal(URLBlacklistLock);
    return contains;
    }
    
    static void URLInBlackListAdd(NSURL *url) {
    if (!url || url == (id)[NSNull null]) return;
    URLBlacklistInit();
    dispatch_semaphore_wait(URLBlacklistLock, DISPATCH_TIME_FOREVER);
    [URLBlacklist addObject:url];
    dispatch_semaphore_signal(URLBlacklistLock);
    }
    

    
    
}
