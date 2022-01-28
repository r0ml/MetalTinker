
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension UserDefaults {

  func color(forKey key: String) -> XColor? {

    guard let colorData = data(forKey: key) else { return nil }

    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClass: XColor.self, from: colorData)
    } catch let error {
      print("color error \(error.localizedDescription)")
      return nil
    }
  }

  func set(_ value: XColor?, forKey key: String) {

    guard let color = value else { return }
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
      set(data, forKey: key)
    } catch let error {
      print("error color key data not saved \(error.localizedDescription)")
    }
  }
}
