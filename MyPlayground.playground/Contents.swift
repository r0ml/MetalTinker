import Cocoa

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

