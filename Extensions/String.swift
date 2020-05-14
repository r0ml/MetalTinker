
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

extension String {

  static public func read(fromFile fileName: String, ofType type : String) -> String {
    let txtFilePath = Bundle.main.path(forResource: fileName, ofType:type)!
    do {
      let txtFileContents = try String.init(contentsOfFile:txtFilePath)
      return txtFileContents
    } catch {
      return "failed to read \(txtFilePath): \(error.localizedDescription)"
    }
  }

  func nameToLabel() -> String {
    var s = self.replacingOccurrences(of: "_", with: " ")
    s = s.trimmingCharacters(in: CharacterSet(charactersIn: " "))
    s = s.capitalized
    return s
  }
}

