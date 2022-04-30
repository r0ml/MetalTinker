
static func makeDepthAttachmentDescriptor(size canvasSize : CGSize) -> MTLRenderPassDepthAttachmentDescriptor {

  let depthAttachmentDescriptor = MTLRenderPassDepthAttachmentDescriptor()
  // set up the depth texture
  let td = MTLTextureDescriptor()
  td.textureType = .type2DMultisample
  td.pixelFormat = .depth32Float
  td.storageMode = .private
  td.usage = [.renderTarget, .shaderRead]
  td.width = Int(canvasSize.width)  // should be the colorAttachments[0]  size
  td.height = Int(canvasSize.height)

  td.sampleCount = 4 // should be multisampleCount -- but I can't see it

  let dt = device.makeTexture(descriptor: td)

  depthAttachmentDescriptor.clearDepth = 1
  depthAttachmentDescriptor.texture = dt
  depthAttachmentDescriptor.loadAction = .clear
  return depthAttachmentDescriptor
}

}
