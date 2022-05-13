// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import Metal

class ShaderPointCloud : ShaderVertex {

   override var myGroup : String {
    get { "PointCloud" }
  }

  override var topology : MTLPrimitiveTopologyClass { get { .point } }


  required init(_ s : String, _ l : MTLLibrary ) {
    //    print("ShaderFilter init \(s)")
    super.init(s, l)
//    function = Function(myGroup)
  }
}
