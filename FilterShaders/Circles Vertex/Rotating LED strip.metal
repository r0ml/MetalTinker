
#define shaderName rotating_led_strip

#include "Common.h" 

fragmentFn() {
  float2 center = uni.iResolution.xy / 2.0;
  float Dist = distance(center, thisVertex.where.xy);
  float Angle = atan2((center.y - thisVertex.where.y), (center.x - thisVertex.where.x));
  float angle = -20.0 * (uni.iTime - (5.0 * cospi( uni.iTime / 5.0))/ PI);
  float velocity = 20.0 * (1.0 + sinpi( uni.iTime / 5.0));
  
  if(mod(Dist, 20.0) < 10.0 && Dist < 120.0) {
    return saturate((mod(Angle + angle, PI) / 4.0) - (1.0 - velocity / 20.0)) * (20.0 / velocity) * float4(thisVertex.where.xy / uni.iResolution.xy, 0.5+0.5*sin(uni.iTime), 1.0);
  } else {
    return float4(0, 0, 0, 0);
  }
}
