//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

// These routines are for XScreenSaver ports
// Most likely these routines get converted to metal code?

import Foundation
import AppKit
import MetalKit
import os

public func makeRandomColormap(_ ncolors : Int, _ isBright : Swift.Bool) -> [NSColor] {

  var colors = [NSColor]()

  for _ in 0..<ncolors {
  if isBright {
    let H = CGFloat.random(in: 0..<1)         // range 0-360
    let S = CGFloat(  Int.random(in: 0..<70) + 30)/100.0 // range 30%-100%
    let V = CGFloat( Int.random(in: 0..<34) + 66)/100.0 // range 66%-100%
      colors.append( NSColor.init(calibratedHue: H, saturation: S, brightness: V, alpha: 1) )
    } else {
    colors.append( NSColor.init(calibratedRed: CGFloat.random(in: 0..<1), green: CGFloat.random(in: 0..<1), blue: CGFloat.random(in: 0..<1), alpha: 1) )
    }
  }

  /* If there are a small number of colors, make sure at least the first
   two contrast well.
   */
/*  if (!bright_p && ncolors <= 4)
  {
    int h0, h1;
    double s0, s1, v0, v1;
    rgb_to_hsv (colors[0].red, colors[0].green, colors[0].blue, &h0,&s0,&v0);
    rgb_to_hsv (colors[1].red, colors[1].green, colors[1].blue, &h1,&s1,&v1);
    if (fabs (v1-v0) < 0.5)
    goto RETRY_ALL;
  }
*/
  return colors
}

public func makeSmoothColormap (_ ncolors : Int) -> [NSColor] {
/*  int npoints;
  int ncolors = *ncolorsP;
  Bool wanted_writable = (allocate_p && writable_pP && *writable_pP);
  int i;
  int h[MAXPOINTS];
  double s[MAXPOINTS];
  double v[MAXPOINTS];
  double total_s = 0;
  double total_v = 0;
  int loop = 0;
*/

  let n = Int.random(in: 0..<20)
  let npoints = n <= 5 ? 2 : n <= 15 ? 3 : n <= 18 ? 4 : 5 // 30%, 50%, 15%, 5% of the time
  var ncols = Array.init(repeating: NSColor.white, count: npoints)

  var total_s : CGFloat = 0
  var total_v : CGFloat = 0

  for i in 0..<npoints {
    let h = CGFloat.random(in: 0..<1)
    let s = CGFloat.random(in: 0..<1)
    let v = CGFloat.random(in: 0..<0.8) + 0.2

    ncols[i] = NSColor.init(calibratedHue: h, saturation: s, brightness: v, alpha: 1)

    // Make sure that no two adjascent colors are *too* close together.  If they are, try again.
    if i > 0 {
      let j = i-1
      let hi = ncols[i].hueComponent
      let hj = ncols[j].hueComponent
      var dh = abs(hj - hi)
      if (dh > 0.5) { dh = 0.5 - (dh - 0.5) }
      let ds = ncols[j].saturationComponent - ncols[i].saturationComponent
      let dv = ncols[j].brightnessComponent - ncols[i].brightnessComponent
      let distance = sqrt (dh * dh + ds * ds + dv * dv);
      os_log("%s", type:.debug, "distance \(distance)")
      if distance < 0.2 {
        os_log("%s", type:.debug, "i should repick this color")
      }
    }
   total_s += s
   total_v += v
  }

  // If the average saturation or intensity are too low, repick the colors, so that we don't end up with a black-and-white or too-dark map.
  if total_s / CGFloat(npoints) < 0.2 {
    os_log("%s", type:.debug, "total_s repick \(total_s / CGFloat(npoints) )")
  }
  if total_v / CGFloat(npoints) < 0.3 {
    os_log("%s", type:.debug, "total_v repick \(total_v / CGFloat(npoints) )")
  }
  return makeColorPath(c : ncols, nncolors: ncolors)
}

public func makeColorPath(c : [NSColor], nncolors : Int) -> [NSColor] {
  if c.count == 2 {
    return makeColorRamp(nncolors, c[0], c[1])
  } else {
    let total_ncolors = nncolors
    var DH : [CGFloat] = Array.init(repeating: 0, count: c.count)

    for i in 0..<c.count {
      let j = (i + 1) % c.count
      let dd = abs(c[i].hueComponent - c[j].hueComponent)
      let d = dd > 0.5 ? 1 - dd : dd
      DH[i]=d
    }

    var edge : [CGFloat] = Array.init(repeating: 0, count: c.count)
    var circum : CGFloat = 0

    for i in 0..<c.count {
      let j = (i+1)%c.count
      let ds = c[j].saturationComponent-c[i].saturationComponent
      let dv = c[j].brightnessComponent-c[i].brightnessComponent
      edge[i] = sqrt( DH[i] * DH[j] + ds * ds + dv * dv)
      circum += edge[i]
    }

    os_log("%s", type:.debug, "circum \(circum)" )
    let ratio = edge.map { $0 / circum }
    let opo = ratio.reduce(0, +)
    os_log("%s", type:.debug, "opo \(opo)")
    var ncolors = ratio.map { Int(0.5 + $0 * CGFloat(total_ncolors) ) }
    var i = ncolors.count
    while( ncolors.reduce(0,+) > total_ncolors ) {
      if i == 0 { i = ncolors.count }
      i -= 1
      ncolors[i] -= 1
    }

    var dh : [CGFloat] = Array.init(repeating: 0, count: c.count)
    var ds = dh
    var dv = ds

    for i in 0..<c.count {
      let j = (i+1)%c.count
      dh[i] = DH[i] / CGFloat(ncolors[i])
      ds[i] = (c[j].saturationComponent - c[i].saturationComponent) / CGFloat(ncolors[i])
      dv[i] = (c[j].brightnessComponent - c[i].brightnessComponent) / CGFloat(ncolors[i])
    }

    var k = 0
    var outcol = Array.init(repeating: NSColor.white, count: nncolors)
    for i in 0..<c.count {
      let jj = (i+1)%c.count
      let distance = c[jj].hueComponent - c[i].hueComponent
      var direction = distance >= 0 ? -1 : 1
      if distance <= 0.5 && distance >= -0.5 { direction = -direction }

      for j in 0..<ncolors[i] {
        var hh = c[i].hueComponent + CGFloat(j) * dh[i] * CGFloat(direction)
        if hh < 0 { hh += 1 }
        else if hh > 1 { hh -= 1 }
        outcol[k] = NSColor.init(calibratedHue: hh, saturation: c[i].saturationComponent + CGFloat(j) * ds[i], brightness: c[i].brightnessComponent + CGFloat(j) * dv[i], alpha: 1)
        k += 1
      }

    }
    return outcol
  }
}

public func makeColorRamp(_ nncolors : Int, _ c1 : NSColor, _ c2 : NSColor) -> [NSColor] {
  let total_ncolors = nncolors
  var cc = Array.init(repeating: NSColor.white, count: nncolors)
  let ncolors = ( total_ncolors / 2 ) + 1

  let dh = ( c2.hueComponent - c1.hueComponent ) / CGFloat(ncolors)
  let ds = ( c2.saturationComponent - c1.saturationComponent ) / CGFloat(ncolors)
  let dv = ( c2.brightnessComponent - c1.brightnessComponent ) / CGFloat(ncolors)

  for i in 0..<ncolors {
    let nc = NSColor.init(calibratedHue: c1.hueComponent + CGFloat(i) * dh, saturation: c1.saturationComponent + CGFloat(i) * ds, brightness: c1.brightnessComponent + CGFloat(i) * dv, alpha: 1)
    cc[i]=nc
    cc[total_ncolors-1-i]=nc
  }
  return cc
}

public func makeUniformColormap(_ nncolors : Int) -> [NSColor] {
  let S = CGFloat.random(in: 0..<0.34) + 0.66
  let V = CGFloat.random(in: 0..<0.34) + 0.66
  let a = makeColorRamp(nncolors / 2, NSColor(calibratedHue: 0, saturation: S, brightness: V, alpha: 1), NSColor(calibratedHue: 0.5, saturation: S, brightness: V, alpha: 1))
  let b = makeColorRamp(nncolors/2, NSColor(calibratedHue: 0.5, saturation: S, brightness: V, alpha: 1), NSColor(calibratedHue: 0.99, saturation: S, brightness: V, alpha: 1))
  return a+b
}

extension NSColor {
  var vf4 : SIMD4<Float> { get { return [Float(self.redComponent), Float(self.greenComponent), Float(self.blueComponent), Float(self.alphaComponent)]}}
}
