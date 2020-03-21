//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import AppKit

extension UserDefaults {

  func color(forKey key: String) -> NSColor? {

    guard let colorData = data(forKey: key) else { return nil }

    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
    } catch let error {
      print("color error \(error.localizedDescription)")
      return nil
    }
  }

  func set(_ value: NSColor?, forKey key: String) {

    guard let color = value else { return }
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
      set(data, forKey: key)
    } catch let error {
      print("error color key data not saved \(error.localizedDescription)")
    }
  }
}
