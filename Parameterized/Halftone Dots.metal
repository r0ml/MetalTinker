
#define shaderName halftone_dots

#include "Common.h" 

struct InputBuffer {
  bool invert;
  int3 dotRows;
  float3 radius;
};
initialize() {
  in.dotRows = {3, 5, 9 };
  in.radius = {0.1, 0.25, 0.5 };
}

fragmentFunc(device InputBuffer &in) {
  // update layout params
  float t = scn_frame.time;
  float rows = in.dotRows.y + 3. * sin(t);
  float curRadius = in.radius.y + 0.15 * cos(t);
  float curRotation = t;
  float2 curCenter = float2(cos(t), sin(t));
  // get original coordinate, translate & rotate
  float2 uv = worldCoordAdjusted;
  uv += curCenter;
  uv = uv * rot2d(curRotation);
  // calc row index to offset x of every other row
  float rowIndex = floor(uv.y * rows);
  float oddEven = mod(rowIndex, 2.);
  // create grid coords
  float2 uvRepeat = fract(uv * rows) - 0.5;
  if(oddEven == 1.) {							// offset x by half
    uvRepeat = fract(float2(0.5, 0.) + uv * rows) - float2(0.5, 0.5);
  }
  // adaptive antialiasing, draw, invert
  float2 reso = 1 / scn_frame.inverseResolution;
  float aa = reso.y * in.dotRows.y * 0.00001;
  float col = smoothstep(curRadius - aa, curRadius + aa, length(uvRepeat));
  if (in.invert == 1) col = 1. - col;
  return float4(float3(col),1.0);
}
