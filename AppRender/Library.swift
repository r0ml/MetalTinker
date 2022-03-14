
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Metal
import os

actor Function {
  private var functionCache = [String : MTLFunction]()
  private var fcQ = DispatchQueue(label: "function cache access")
  func find(_ fn : String) async -> MTLFunction? {
    guard let f = functionCache[fn] else {
      functionCache[fn] = findNoCacheFunction(fn)
      return functionCache[fn]
    }
    return f
  }
  
  /** Look up a function name in the libraries and return the MTLFunction for that name */
  private func findNoCacheFunction(_ n : String) -> MTLFunction? {
    guard let k = functionMap[n] else { return nil }
    return Function.metalLibraries[k].makeFunction(name: n)
  }

  /** A mapping between function names and the metal library they are found in */
  lazy var functionMap : [String : Int ] = {
    // This will blow up if there is a duplicate name in two different libraries
    // so I changed it to map each function name to a list of libraries
    // I would have liked to know which names were duplicate, but uniquingKeysWith: only provides values, not the key
    let res = Dictionary(Function.metalLibraries.enumerated().flatMap { ml in ml.1.functionNames.map { ($0, [ml.0] )  } },
                         uniquingKeysWith: { $0 + $1 } )
    res.forEach { if $0.1.count > 1 {
      os_log("duplicate metal function definition %s: %s", type: .info, $0.0, ($0.1.map { Function.metalLibraries[$0].label! }).joined(separator: ", "))  } }
    return Dictionary( uniqueKeysWithValues: res.map { ($0.0, $0.1[0]) } )
  }()

  static func mtlLibs(_ u : URL?) -> [MTLLibrary] {
    guard let u = u else {
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

  /** All the metal libraries in Resources */
  static var metalLibraries : [MTLLibrary] = {
    return mtlLibs( Bundle.main.resourceURL )
  }()

  static var filterLibraries : [MTLLibrary] = {
    return mtlLibs( URL(string: "Filters", relativeTo:  Bundle.main.resourceURL) )
  }()

}
