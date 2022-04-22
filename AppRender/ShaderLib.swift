
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit

class ShaderLib<T : GenericShader> : Identifiable, Equatable, Hashable {
  static func == (lhs: ShaderLib, rhs: ShaderLib) -> Bool {
    return lhs.lib.label == rhs.lib.label
  }
  
  func hash(into hasher: inout Hasher) {
    lib.label.hash(into: &hasher)
  }
  
  var lib : MTLLibrary
  
  init(lib l: MTLLibrary) {
    lib = l
  }
  
  public var id : String {
    return lib.label ?? "none"
  }
  
  static func folderList() -> [ShaderLib<ShaderTwo>] {
    return functionMaps["Shaders"]!.shaderLib()
  }

  static func filterList() -> [ShaderLib<ShaderFilter>] {
    return functionMaps["Filters"]!.shaderLib()
  }

  static func generatorList() -> [ShaderLib<GenericShader>] {
    return functionMaps["Generators"]!.shaderLib()
  }



  lazy var items : [T] = {
    // FIXME: need some other way to identify the list of "shaders"
    //    if cache != nil { return cache! }
    let a = try! NSRegularExpression(pattern: #"^(?<name>.*?)___(?<pass>.*?)___(?<suffix>.*?)$"#)

    let res = lib.functionNames.compactMap { (nam) -> String? in
      let b = a.matches(in: nam, range: NSRange(location: 0, length: nam.count))
      if let c = b.first {
        let d = c.range(withName: "name")
        if d.length == 0 {
          return nil
        }
        let j = nam.index(nam.startIndex, offsetBy: d.location)
        let k = nam.index(j, offsetBy: d.length)
        return String(nam[j..<k])
      }
      return nil
    }
    return Set(res).sorted { $0.lowercased() < $1.lowercased() }.map { T.init($0) }
    //    return cache!
  }()
}
