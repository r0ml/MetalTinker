
#define shaderName baby_first_metaballs

#include "Common.h" 

fragmentFunc() {
  const int kNum = 4;
  float sum_of_influence = 0.;
  float t = scn_frame.time;

  for (int i = 0; i < kNum; ++i)
  {
    float idx = float(i+1);
    
    float2 position = float2(
                             //            "wiggliness"                             |   15% of the screen   |  start at the ctr
                             (cos(t * 0.5) + cos(t * idx * .3)) * 0.17 + 0.5,
                             (sin(t * 0.3) + sin(t * idx * .7)) * 0.15 + 0.5
                             );
    float radius = 0.01 * idx;
    float dist = distance(textureCoord, position);
    
    // wiggle the distance to the ball based on direction of ball to point
    float2 direction = normalize(textureCoord - position);
    float angle = atan2(direction.y, direction.x);
    float perimeter_offset = sin(angle * 7.) + sin((t + angle) * 3. * idx);
    radius += perimeter_offset * (radius * .1); // at most 10% adjustment
    
    float influence = radius / dist;
    
    sum_of_influence += influence;
  }
  
  // this creates a pulsing external color with a sharp falloff
  float pulse = abs(sin(t)) * 10. + 4.;
  float color = pow(sum_of_influence, pulse);
  
  if (color <= 1.)
  {
    // base color is a function of how close you are to being "inside" a metaball
    // left and right make you more blue, up and down make you more red
    float2 st = textureCoord;
    return float4(
                  color * (1. - (abs(st.x - .5) / .5)), 0.,
                  color * (1. - (abs(st.y - .5) / .5)), 1.0);
  }
  discard_fragment();
  return 0;
}
