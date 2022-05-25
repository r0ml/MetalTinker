import Cocoa
import simd
import SceneKit

let a = simd_quatf(ix: 1, iy: 0, iz: 0, r: 3)
a.real
a.imag


let b = a.vector

b.x
b.y
b.z
b.w

a.normalized


let c = a.normalized.vector

c.x
c.y
c.z
c.w

let j = SCNQuaternion(x:1, y: 0, z:0, w: 3)

let k = SCNVector4(x: 1, y: 0, z: 0, w: 3)




/*

let a = try? NSRegularExpression(pattern: #"^(?<name>.*?)___(?<pass>.*?)___(?<suffix>.*?)$"#)
let b = "Hello___3___playground"

let c  = a?.matches(in: b, range: NSRange(location: 0, length: b.count))

c?.count
let d = c![0]
d.range(at: 0)
d.numberOfRanges
d.range(at: 1)
d.range(at: 2)
d.range(at: 3)

let e = d.range(withName: "name")
d.range(withName: "clem")

let j = b.index(b.startIndex, offsetBy: e.location)
let k = b.index(j, offsetBy: e.length)

b[j..<k]

*/
