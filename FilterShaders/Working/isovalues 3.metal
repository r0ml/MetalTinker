
#define shaderName isovalues_3

#include "Common.h" 

static float noise(float3 x) {
  return (noisePerlin(x)+noisePerlin(x+11.5)) / 2.; // pseudoperlin improvement from foxes idea
}

fragmentFn( texture2d<float> lastFrame ) {
  constexpr sampler chan(coord::normalized, address::clamp_to_edge, filter::linear);

  float2 R = uni.iResolution;
  float n = noise(float3(thisVertex.where.xy*8./R.y, .1*uni.iTime));
  float v = sin(TAU*10.*n);
  float t =  uni.iTime;

  v = smoothstep(1.,0., .5*abs(v)/fwidth(v));

  return mix( exp(-33./R.y ) * lastFrame.sample( chan, (thisVertex.where.xy+float2(1,sin(t)))/R), // .97
             .5+.5*sin(12.*n+float4(0,2.1,-2.1,0)),
             v );

}

