
#define shaderName metaballs_get_together

#include "Common.h" 

constant const float vertices = 8.;
constant const float startIndex = vertices;
constant const float endIndex = vertices * 2.;

static float metaballs(float2 uv, float time) {
  // float timeOsc = sin(time);										// oscillation helper
  float size = 0.5;												// base size
  float radSegment = TAU / vertices;
  for(float i = startIndex; i < endIndex; i++) {					// create x control points
    float rads = i * radSegment;								// get rads for control point
    float radius = 1. + 1.5 * sin(time + rads * 1.);
    float2 ctrlPoint = radius * float2(sin(rads), cos(rads));		// control points in a circle
    size += 1. / pow(i, distance(uv, ctrlPoint));				// metaball calculation
  }
  return size;
}

fragmentFunc() {
  float time = scn_frame.time * 2.;
  float2 uv = worldCoordAdjusted;	// center coordinates
  uv *= 3.; 														// zoom out
  float col = metaballs(uv, time);
  col = smoothstep(0., fwidth(col)*1.5, col - 1.);				// was simple but aliased: smoothstep(0.98, 0.99, col);
  return float4(1. - sqrt(float3(col)), 1); 						// Rough gamma correction.
}
