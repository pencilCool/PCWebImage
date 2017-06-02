//
//  PCHelper.swift
//  PCImageCache
//
//  Created by tangyuhua on 2017/6/2.
//  Copyright © 2017年 tangyuhua. All rights reserved.
//

import Foundation

import Foundation
func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType)
    -> ValueType {
        if let associated = objc_getAssociatedObject(base, key)
            as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject(base, key, associated,
                                 .OBJC_ASSOCIATION_RETAIN)
        return associated
}
func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType) {
    objc_setAssociatedObject(base, key, value,
                             .OBJC_ASSOCIATION_RETAIN)
}

class YYShared {
    static func application() -> UIApplication? {
        var isAppExtension = false
        guard let cls = NSClassFromString("UIApplication") else {
            return nil
        }
        if cls.responds(to: #selector(getter: UIApplication.shared)) {
            isAppExtension = true
        }
        if Bundle.main.bundlePath.hasSuffix(".appex") {
            isAppExtension = true
        }
        
        if isAppExtension {
            return nil
        } else {
            return UIApplication.shared
        }
    }
}


