
#define shaderName particle_experiment_6

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {

  float t = uni.iTime+5.;
  float z = 6.;

  const int n = 100; // particle count

  float3 startColor = float3(0,0.64,0.2);
  float3 endColor = float3(0.06,0.35,0.85);

  float startRadius = 0.84;
  float endRadius = 1.6;

  float power = 0.51;
  float duration = 4.;

  float2
  s = uni.iResolution,
  v = z*(2.*thisVertex.where.xy-s)/s.y;

  // Mouse axis y => zoom
  if (uni.wasMouseButtons) v *= uni.iMouse.y * 20.;

  // Mouse axis x => duration
  if (uni.wasMouseButtons) duration = uni.iMouse.x * 10.;

  float3 col = float3(0.);

  // float2 pm = v.yx*2.8;

  float dMax = duration;

  float evo = (sin(uni.iTime*.01+400.)*.5+.5)*99.+1.;

  float mb = 0.;
  float mbRadius = 0.;
  float sum = 0.;
  for(int i=0;i<n;i++) {
    float d = fract(t*power+48934.4238*sin(float(i/int(evo))*692.7398));

    // float tt = 0.;

    float a = TAU*float(i)/float(n);

    float x = d*cos(a)*duration;

    float y = d*sin(a)*duration;

    float distRatio = d/dMax;

    mbRadius = mix(startRadius, endRadius, distRatio);

    float2 p = v - float2(x,y);//*float2(1,sin(a+PI/2.));

    mb = mbRadius/dot(p,p);

    sum += mb;

    col = mix(col, mix(startColor, endColor, distRatio), mb/sum);
  }

  sum /= float(n);

  col = normalize(col) * sum;

  sum = clamp(sum, 0., .4);

  float3 tex = float3(1.);

  col *= smoothstep(tex, float3(0.), float3(sum));

  return float4( col * 0.05 + lastFrame.sample(iChannel0, thisVertex.where.xy/s).rgb*0.95, 1);
}
