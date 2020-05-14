
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

class Message : ObservableObject {
  @Published var msg : String = "" {
    willSet {
      print("message set")
    }
  }
}

class Observable<T> : ObservableObject {
  var f : ((T) -> Void)?
  
  @Published var x : T {
    didSet {
      if let f = f { f(x) }
      objectWillChange.send()
    }
  }
  
  init( _ y : T, f : ((T) -> Void)? = nil ) {
    x = y
    self.f = f
  }
}
