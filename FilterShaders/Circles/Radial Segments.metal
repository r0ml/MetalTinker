
#define shaderName Radial_Segments

#include "Common.h"

fragmentFn() {
  float time = uni.iTime * 4.;									// adjust time
  float2 uv = worldCoordAspectAdjusted;
  float radsPercent = atan2(uv.x, uv.y) / TAU;           		// get angle to center
  float dist = length(uv) * 5.; // distance(uv, center);   		// multiply radius to achieve smaller rings
  float ringSegments = 1. + floor(dist * 4.);				 		// number of ring segments depends on radius
  if(mod(ringSegments, 2.) == 0.) time = -time;            		// reverse time for even-numbered rings
  time *= ringSegments * 0.2;                              		// increase time/spin moving out from center
  time = 0.02 * sin(time);								 		// remap time into an oscillation
  float ringRadsOffset = 0.; // 6. * sin(ringSegments);    		// possible unique offset per ring
  radsPercent = mod(time + radsPercent + ringRadsOffset, 1.); 	// rotate individual rings
  if(mod(ringSegments, 2.) == 1.) ringSegments++; 				// make sure we have even number of segments
  float segment = radsPercent * ringSegments;						// progress around circle
  float segmentNumber = floor(segment);							// iterate over ring segments - get segment number
  float colFade = pow(fract(segment), 10.);						// go from black to white on a curve at the end
  float3 col = float3(colFade);										// default to black
  if(mod(segmentNumber, 2.) == 0.) col = float3(1. - colFade);		// color every other segment white
  return float4(col, 1.);
}
