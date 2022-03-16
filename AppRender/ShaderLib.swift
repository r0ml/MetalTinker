
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit

class ShaderLib<T : Shader> : Identifiable, Equatable, Hashable {
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
    return ShaderTwo.function.shaderLib()
  }

  static func filterList() -> [ShaderLib<ShaderFilter>] {
    return ShaderFilter.function.shaderLib()
  }

  lazy var items : [T] = {
    // FIXME: need some other way to identify the list of "shaders"
    //    if cache != nil { return cache! }
    let res = lib.functionNames.compactMap { (nam) -> String? in
      var pnam : String
      if nam.hasSuffix("InitializeOptions") {
        pnam = String(nam.dropLast(17))
      } else {
        return nil
      }
      return pnam
    }
    return Set(res).sorted { $0.lowercased() < $1.lowercased() }.map { T.init($0) }
    //    return cache!
  }()
}
