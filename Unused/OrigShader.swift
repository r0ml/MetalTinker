
  
  required init(_ s : String ) {
    
    myName = (s.filter { !":()[].".contains($0) })
      .replacingOccurrences(of: " ", with: "_")
      .replacingOccurrences(of: "-", with: "_")
      .replacingOccurrences(of: "é", with: "e")
    
    Task.detached {
      self.config = Config(s)
      await self.config?.doInitialization()
      
      let depthStencilDescriptor = MTLDepthStencilDescriptor()
      depthStencilDescriptor.depthCompareFunction = .less
      depthStencilDescriptor.isDepthWriteEnabled = true // I would like to set this to false for triangle blending
      self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
  }
    

func makeRenderPassDescriptor(label : String, size canvasSize: CGSize) -> MTLRenderPassDescriptor {
  //------------------------------------------------------------
  // texture on device to be written to..
  //------------------------------------------------------------
  let ts = makeRenderPassTexture(label, size: canvasSize)!
  let texture = ts.0
  let resolveTextures = (ts.1, ts.2)
  
  let renderPassDescriptor = MTLRenderPassDescriptor()
  renderPassDescriptor.colorAttachments[0].texture = texture
  renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
  renderPassDescriptor.colorAttachments[0].resolveLevel = 0
  renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTextures.1 //  device.makeTexture(descriptor: xostd)
  renderPassDescriptor.colorAttachments[0].loadAction = .clear // .load
  //      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)
  
  
  // only if I need depthing?
  renderPassDescriptor.depthAttachment = RenderPipelinePass.makeDepthAttachmentDescriptor(size: canvasSize)
  
  return renderPassDescriptor
}
