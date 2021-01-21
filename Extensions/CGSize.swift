// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

extension CGSize {
  public func asPoint() -> CGPoint {
    return CGPoint(x: width, y: height)
  }

  public static func *(left: CGSize, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.width * right.x, y: left.height * right.y)
  }

  public static func /(left: CGSize, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.width / right.x, y: left.height / right.y)
  }

  public static func -(left: CGSize, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.width - right.x, y: left.height - right.y)
  }

  public static func +(left: CGSize, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.width + right.x, y: left.height + right.y)
  }

  public static func *(left: CGSize, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.width * right, y: left.height * right)
  }

  public static func /(left: CGSize, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.width / right, y: left.height / right)
  }

  public static func -(left: CGSize, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.width - right, y: left.height - right)
  }

  public static func +(left: CGSize, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.width + right, y: left.height + right)
  }

}
