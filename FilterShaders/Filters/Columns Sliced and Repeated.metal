
#define shaderName Columns_Sliced_and_Repeated

#include "Common.h"

fragmentFunc(texture2d<float> tex) {
  float columns = 6.;//4. + 3.5 * sin(uni.iTime);
  float columnWidth = 1. / columns;
  float t = scn_frame.time;
  float scrollProgress = 0.5 + 1./2. * sin(PI + t);
  float zoom = 1. + 0.5 * sin(t);
  float aspect = 4.5/3.;
  float padding = 0.15 + 0.15 * sin(t);
  float4 color = float4(1.);
  
  // get coordinates, rotate & fix aspect ratio
  float2 uv = worldCoordAdjusted;
  uv = uv * rot2d(0.2 * sin(t));
  uv.y *= aspect; // fix aspect ratio
  
  // create grid coords & set color
  float2 uvRepeat = fract(uv * zoom);
  
  // calc columns and scroll/repeat them
  float colIndex = floor(uvRepeat.x * columns) + 1.;
  float yStepRepeat = colIndex * scrollProgress;
  uvRepeat += float2(0., yStepRepeat);
  uvRepeat = fract(uvRepeat);
  
  // add padding
  uvRepeat.y *= 1. + padding;
  uvRepeat.y -= padding;
  uvRepeat.x *= (columnWidth + padding * 1.) * columns;
  uvRepeat.x -= padding * colIndex;
  if(uvRepeat.y > 0. && uvRepeat.y < 1.) {
    if(uvRepeat.x < columnWidth * colIndex && uvRepeat.x > columnWidth * (colIndex - 1.)) {
      color = tex.sample(iChannel0, uvRepeat);
    }
  }
  
  // set it / forget it
  return color;
}
