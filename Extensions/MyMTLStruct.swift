
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Metal

class MyMTLStruct {
  let buffer : MTLBuffer
  let offset : Int
  let structure : MTLStructType?
  let datatype : MTLDataType
  let texture : MTLTextureReferenceType?
  let name : String!
  
  // At the top level, there is no Struct Member, so there is no
  // notion of array
  init( _ buf : MTLBuffer, _ struc : MTLArgument) {
    buffer = buf
    structure = struc.bufferStructType!
    offset = 0
    datatype = .struct
    name = struc.name
    texture = nil
  }
  
  private init( _ buf : MTLBuffer, _ nam : String, _ struc : MTLStructType, _ off : Int) {
    buffer = buf
    structure = struc
    offset = off
    datatype = .struct
    texture = nil
    name = nam
  }

  private init( _ buf : MTLBuffer, _ nam : String, _ s : MTLDataType, _ off : Int) {
    buffer = buf
    structure = nil
    offset = off
    datatype = s
    name = nam
    texture = nil
  }

  private init(_ buf : MTLBuffer, _ nam : String, _ s : MTLTextureReferenceType, _ off : Int) {
    buffer = buf
    structure = nil
    offset = off
    texture = s
    datatype = .texture
    name = nam
  }

  func getStructArray( _ nam : String) -> [MyMTLStruct]? {
    if let mm = structure?.memberByName(nam),
      let ms = mm.arrayType(),
      let me = ms.elementStructType() {
      return (0..<ms.arrayLength).map {
        MyMTLStruct.init(buffer, nam, me, offset + mm.offset + $0 * ms.stride)
      }
    }
    if let m = self[nam] {
      return [m]
    }
    return nil
  }
  
  var children : [MyMTLStruct] { get {
    if let mm = structure?.members {
      return mm.map {
        return getMyMTLStruct($0)
      }
    }
    return []
    }
  }
  
  subscript(index:String) -> MyMTLStruct? {
      get {
        if let mdef = structure?.memberByName(index) {
          return getMyMTLStruct(mdef)
        }
        return nil
      }
//      set(newElm) {
//          list.insert(newElm, atIndex: index)
//      }
  }
  
  private func getMyMTLStruct(_ mdef : MTLStructMember) -> MyMTLStruct {
    if let ms = mdef.structType() {
      return MyMTLStruct.init(buffer, mdef.name, ms, offset + mdef.offset)
      // FIXME:
    } else if let ms = mdef.textureReferenceType() {
      return MyMTLStruct.init(buffer, mdef.name, ms, offset + mdef.offset)
    } else {
      return MyMTLStruct.init(buffer, mdef.name, mdef.dataType, offset+mdef.offset )
    }
  }
  
  func getValue<T>() -> T {
    return buffer.contents().advanced(by: offset).assumingMemoryBound(to: T.self).pointee
  }

  func setValue<T>(_ val : T) {
    buffer.contents().advanced(by: offset).assumingMemoryBound(to: T.self).pointee = val
   // buffer.didModifyRange( offset ..< offset + MemoryLayout.size(ofValue: val))
  }

  // used by ColorUpdater
  func getBufPtr<T>() -> UnsafeMutablePointer<T>  {
    return buffer.contents().advanced(by: offset).assumingMemoryBound(to: T.self)
  }
  
  var value : Any? { get {
    
    switch(datatype) {
    case .bool :
      return buffer.contents().advanced(by: offset).assumingMemoryBound(to: Bool.self).pointee
    case .int :
      return Int(buffer.contents().advanced(by: offset).assumingMemoryBound(to: Int32.self).pointee)
    case .int2 :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: SIMD2<Int32>.self).pointee
      return v  // (Int(v.x), Int(v.y))
    case .int3 :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: SIMD3<Int32>.self).pointee
      return v  // (Int(v.x), Int(v.y))
    case .int4 :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: SIMD4<Int32>.self).pointee
      return v  // (Int(v.x), Int(v.y))
      
    case .float :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: Float.self).pointee
      return v  // (Int(v.x), Int(v.y))
    case .float2 :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: SIMD2<Float>.self).pointee
      return v  // (Float(v.x), Float(v.y))
    case .float3 :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: SIMD3<Float>.self).pointee
      return v  // (Float(v.x), Float(v.y))
    case .float4 :
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: SIMD4<Float>.self).pointee
      return v  // (Float(v.x), Float(v.y))
    case .sampler:
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: MTLSamplerState.self).pointee
      return v
    case .texture:
      let v = buffer.contents().advanced(by: offset).assumingMemoryBound(to: MTLTexture.self).pointee
      return v
    default: return nil
    }
    }
  }

  func getString() -> String? {
    if let bstn = structure?.memberByName("name"),
      let at = bstn.arrayType(),
      at.elementType == .char {
      let ll = at.arrayLength
      let bb = buffer.contents().advanced(by: offset + bstn.offset).bindMemory(to: CChar.self, capacity: ll)
      let res = String(cString: bb)
   //   print("\(nam) = \(res)")
      return res
    }
    return nil
  }
}
