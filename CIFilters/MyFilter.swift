// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import CoreImage

public class MyFilter : CIFilter {

  private let kernel: CIKernel

  public init?(_ fn : String) {
    let url = Bundle.main.url(forResource: "CIFilters", withExtension: "metallib")!
    if let data = try? Data(contentsOf: url),
      let k = try? CIKernel(functionName: fn, fromMetalLibraryData: data) {
      kernel = k
      super.init()
    } else {
      return nil
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func doit(_ im : CIImage, _ arg : Any... ) -> CIImage? {
    let z = kernel.apply(extent: im.extent, roiCallback: { (x,y) in
      return y
    }, arguments: [im]+arg)
    return z
  }
}
