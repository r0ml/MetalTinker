
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Metal
import os


// FIXME: should this not be an actor?
class Function {
  
  private var functionCache = [String : MTLFunction]()
  private var fcQ = DispatchQueue(label: "function cache access")
  
  
  func find(_ fn : String) -> MTLFunction? {
    guard let f = functionCache[fn] else {
      functionCache[fn] = findNoCacheFunction(fn)
      return functionCache[fn]
    }
    return f
  }
  
  /** Look up a function name in the libraries and return the MTLFunction for that name */
  private func findNoCacheFunction(_ n : String) -> MTLFunction? {
    guard let k = functionMap[n] else { return nil }
    return libs[k].makeFunction(name: n)
  }

  var functionMap : [String : Int] = [:]
  var libs : [MTLLibrary]
  
  /** A mapping between function names and the metal library they are found in */
  init( _ s : String) {
    libs = Self.mtlLibs(s)
    let k = libs
    // This will blow up if there is a duplicate name in two different libraries
    // so I changed it to map each function name to a list of libraries
    // I would have liked to know which names were duplicate, but uniquingKeysWith: only provides values, not the key
    let res = Dictionary(libs.enumerated().flatMap { ml in ml.1.functionNames.map { ($0, [ml.0] )  } },
                         uniquingKeysWith: { $0 + $1 } )
    res.forEach { if $0.1.count > 1 {
      os_log("duplicate metal function definition %s: %s", type: .info, $0.0, ($0.1.map { k[$0].label! }).joined(separator: ", "))  } }
    functionMap = Dictionary( uniqueKeysWithValues: res.map { ($0.0, $0.1[0]) } )
  }

  static func mtlLibs(_ s : String) -> [MTLLibrary] {
    guard let u = URL(string: s, relativeTo:  Bundle.main.resourceURL) else {
      os_log("failure to find resource URL", type:.fault)
      return []
    }
    let list = (try? FileManager.default.contentsOfDirectory(
      at: u,
      includingPropertiesForKeys: [URLResourceKey.contentModificationDateKey, .creationDateKey, .fileSizeKey, .nameKey, .pathKey],
      options: .skipsSubdirectoryDescendants)) ?? []
    return list.filter({ $0.pathExtension == "metallib" }).compactMap { url -> MTLLibrary? in
      let lib = try? device.makeLibrary(URL: url)
      lib?.label = url.deletingPathExtension().lastPathComponent
      return lib
    }
  }
  
  func shaderLib<T>() -> [ShaderLib<T>] {
    return libs.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }.map { ShaderLib<T>(lib: $0)}
  }
  

}
