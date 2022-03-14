import Cocoa

var str = "Hello, playground"

let string = "testing_1____1___"
var range = string.range(of: #"(.*)___(.*)___"#, options: [.regularExpression])
range?.debugDescription


string[range!]

let regex = try? NSRegularExpression(pattern: "(.*?)___(.*)___", options: [] )

let mm = regex!.matches(in: string, options: [], range: NSRange(location: 0, length: string.count) )

mm.count
let r = Range(mm[0].range(at: 1), in: string)!
String(string[r])
