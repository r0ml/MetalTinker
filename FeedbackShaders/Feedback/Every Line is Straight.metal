
#define shaderName Every_Line_is_Straight

#include "Common.h"

struct InputBuffer {
  int3 maxPoints;
};

initialize() {
  in.maxPoints = {100, 512, 1024};
}

fragmentFn(texture2d<float> lastFrame) {

  // Properties of the overall circle.
  float2 circle_center = (uni.iResolution.xy * 0.5);
  float circle_radius = min(circle_center.x, circle_center.y);
  
  // Properties of the individual points/circles that make up the overall circle.
  float point_radius = circle_radius / 16.0;
  int num_points = min(int(pow(2.0, floor(uni.iTime / PI))), in.maxPoints.y);
  
  // Start with the fragColor from the previous frame (blur effect).
  float4 fragColor = lastFrame.sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy);
  
  // Mix in the color of all the individual points.
  for (int point_index = 0; point_index < num_points; point_index++)
  {
    float point_angle = PI * float(point_index) / float(num_points);
    float2 point_center = float2(cos(point_angle), sin(point_angle));
    point_center *= circle_radius;
    point_center *= cos((PI * uni.iTime / PI * 2.0) - point_angle); // oscillating
    point_center += circle_center;
    
    float point_dist = length(thisVertex.where.xy - point_center);
    if (point_dist < point_radius)
    {
      float3 hsv = float3(abs(sin(point_angle + uni.iTime / 2.0)), 1.0, 1.0);
      fragColor = mix(fragColor, float4(hsv2rgb(hsv), 1.0), 0.5);
    }
  }
  fragColor.w = 1;
  
  return fragColor;
}
