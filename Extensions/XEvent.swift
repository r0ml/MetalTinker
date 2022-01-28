// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

#if os(macOS)
import AppKit
typealias XEvent = NSEvent

#else
import UIKit
typealias XEvent = UIEvent

#endif
