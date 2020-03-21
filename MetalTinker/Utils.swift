//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import os
import MetalKit
import Accelerate

public var config : URLSessionConfiguration {
  let a = URLSessionConfiguration.default
  a.allowsCellularAccess = false
  a.httpMaximumConnectionsPerHost = 4
  a.httpShouldUsePipelining = true
  a.timeoutIntervalForRequest = 30.0
  a.networkServiceType = .background
  a.requestCachePolicy = .reloadRevalidatingCacheData
  return a
}
public var session = URLSession(configuration: config)
public var downloadingQ : DispatchQueue = DispatchQueue(label: "downloading", qos: .background,  attributes: .concurrent)

public enum ShaderSettings : Int {
  case QualityNormal
  case QualityHigh
}

class RunningTransformer: ValueTransformer {
  override class func transformedValueClass() -> AnyClass { return NSString.self }
  override class func allowsReverseTransformation() -> Bool { return false }
  
  override func transformedValue(_ value: Any?) -> Any? {
    guard let b = value as? Bool else { return nil }
    return b ? "Pause" : "Play"
  }
}

class RunningImageTransformer: ValueTransformer {
  override class func transformedValueClass() -> AnyClass { return NSImage.self }
  override class func allowsReverseTransformation() -> Bool { return false }
  
  override func transformedValue(_ value: Any?) -> Any? {
    guard let b = value as? Bool else { return nil }
    
    let a = NSImage.init(named: "pause")
    let c = NSImage.init(named: "play")
    return b ?  a : c
  }
}

func gcd(_ m: Int, _ n: Int) -> Int {
  var a = 0
  var b = max(m, n)
  var r = min(m, n)
  
  while r != 0 {
    a = b
    b = r
    r = a % b
  }
  return b
}
