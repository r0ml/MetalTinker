
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os
import SwiftUI
import SceneKit

#if targetEnvironment(macCatalyst)
import UIKit
#endif

/* TODO:
 1) There is a flicker when resuming after pause (on macCatalyst).  The first frame after pause seems to (someetimes) be frame 0 -- not the current frame
 2) Can I update the thumbnail as the video plays?
 3) Single step is not working
 4) recording and snapshotting is not working
 5) instead of using a separate initialization function in the shader, I could use the fragment function (which also has the "in" parameter) and have the shader macro call initialize() on frame 0
 6) Camera sometimes doesn't shut off when moving to different shader.
 7) Need to set the zoom explicitly (it stays set to previous user -- so Librorum altered it -- for MacOS only it seems
 8) aspect ratio seems off for MacOS on second camera
 9) Switching cameras doesn't turn off the one being switched away from (macOS)
 10) Snapshot icon doesn't show up for MacCatalyst
 */

class ParameterizedShader : GenericShader {

  override var myGroup : String {
    get { "Parameterized" }
  }


  required init(_ s : String ) {
    super.init(s)
  }

}
