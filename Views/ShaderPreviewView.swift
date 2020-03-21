//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import SwiftUI

struct ShaderPreviewView: View {
  @ObservedObject var shader : RenderManager
  let pSize : CGSize
  
  let broken : CGImage = NSImage(named: "BrokenImage")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
  
    var body: some View {
      ZStack(alignment: .bottomLeading) {
        Image(decorative:shader.previewImage(pSize) ?? broken, scale: 1.0 /*?? RenderManager.brokenImage */).resizable().scaledToFit()
        ZStack {
          Text(shader.myName).padding(EdgeInsets.init(top: 4, leading: 8, bottom: 4, trailing: 8))
        }.background(Color.black.opacity(0.6))
      }
    }
}

struct ShaderPreviewView_Previews: PreviewProvider {
    static var previews: some View {
      ShaderPreviewView(shader : RenderManager("simple"), pSize: CGSize(width: 400, height: 300))
    }
}
