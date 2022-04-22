
// FIXME: fix the mouse handling

#define shaderName Distance_Field_Painter

#include "Common.h"
struct KBuffer {  };
initialize() {}

  // Radius of the pen in pixels.
#define PEN_RADIUS 5.0

fragmentFn1() {
  FragmentOutput fff;

  float2 nearest2 = renderInput[0].sample(iChannel0, thisVertex.barrio.xy).xy;
  float dist = distance(nearest2, thisVertex.barrio.xy);
  float level = saturate(dist * 8);

  float3 hsv = float3(level, 1.0 - level, 1.0 - level);

  fff.fragColor.rgb = gammaDecode(hsv2rgb(hsv));
  fff.fragColor.a = 1.0;

  // ============================================== buffers =============================

  // Initialise on first frame.
  if (uni.iFrame <10) {
    fff.pass1 = float4(1, 1, 0.0, 1.0);
    return fff;
  }

  // If the mouse button is down and this pixel is covered by the
  // pen, then mark this pixel as part of the seed area. Otherwise,
  // look in the surrounding 8 pixels for anything nearer to the
  // seed area than this pixel currently is.
  float2 nearest;
  if ( uni.mouseButtons && distance(uni.iMouse.xy, thisVertex.barrio.xy) < PEN_RADIUS / uni.iResolution.x ) {
    nearest = thisVertex.barrio.xy;
  }
  else {
    float4 texVal = renderInput[0].sample(iChannel0, thisVertex.barrio.xy);
    nearest = texVal.xy;
    float dist = distance(nearest, thisVertex.barrio.xy);
    
    float2 offsets[8];
    // x, y = offset in pixels from the current pixel; z = distance covered by that offset.
    offsets[0] = float2(-1.0, -1.0);
    offsets[1] = float2( 0.0, -1.0);
    offsets[2] = float2( 1.0, -1.0);
    offsets[3] = float2(-1.0,  0.0);
    offsets[4] = float2( 1.0,  0.0);
    offsets[5] = float2(-1.0,  1.0);
    offsets[6] = float2( 0.0,  1.0);
    offsets[7] = float2( 1.0,  1.0);

    for (int i = 0; i < 8; ++i) {
      float4 newTexVal = renderInput[0].sample(iChannel0, thisVertex.barrio.xy + offsets[i] / uni.iResolution);
      float newDist = distance(newTexVal.xy, thisVertex.barrio.xy);
      if (newDist < dist) {
        nearest = newTexVal.xy;
        dist = newDist;
      }
    }
  }

  fff.pass1 = float4(nearest, 0.0, 1.0);
  return fff;
}
