
#define shaderName particle_experiment_8

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {

  float t = uni.iTime+5.;

  // vars
  float z = 2.5;

  const int n = 100; // particle count

  float3 startColor = normalize(float3(1.,0.,0.));
  //float3 endColor = normalize(float3(0.2,0.2,.8));
  float3 endColor = normalize(float3(1.,sin(t)*.5+.5,cos(t)*.5+.5));

  float startRadius = 1.;
  float endRadius = 2.;

  float power = 0.8;
  float duration = 4.;

  float2
  s = uni.iResolution,
  v = z*(2.*thisVertex.where.xy-s)/s.y;

  // Mouse axis y => zoom
  if (uni.wasMouseButtons) v *= uni.iMouse.y * 20.;

  // Mouse axis x => duration
  if (uni.wasMouseButtons) duration = uni.iMouse.x * 10.;

  float3 col = float3(0.);

  float2 pm = v.yx*2.8;

  float dMax = duration;

  float mb = 0.;
  float mbRadius = 0.;
  float sum = 0.;
  for(int i=0;i<n;i++)
  {
    float d = fract(t*power+48934.4238*sin(float(i)*692.7398))*duration;
    float a = TAU*float(i)/float(n);

    float x = d*cos(a);
    float y = d*sin(a);

    float distRatio = d/dMax;

    mbRadius = mix(startRadius, endRadius, distRatio);

    float2 vv = mod(v,pm);
    if (isnan(vv.x)) { vv.x = 0; }
    if (isnan(vv.y)) { vv.y = 0; }
    v = vv - 0.5*pm;

    float2 p = v - float2(x,y);

    float2 pp = mod(p, pm);
    if (isnan(pp.x)) { pp.x = 0; }
    if (isnan(pp.y)) { pp.y = 0; }
    p = pp - 0.5*pm;

    float ppp = dot(p,p);

    mb = ppp == 0 ? 100000 : mbRadius/ppp;

    sum += mb;

    col = mix(col, mix(startColor, endColor, distRatio), mb/sum);
  }

  sum /= float(n);

  col = normalize(col) * sum;

  sum = clamp(sum, 0., .5);

  float3 tex = float3(1.);

  col *= smoothstep(tex, float3(0.), float3(sum));

  return float4(col,1) * 0.2 + lastFrame.sample(iChannel0, thisVertex.where.xy/s) * 0.8;
}
