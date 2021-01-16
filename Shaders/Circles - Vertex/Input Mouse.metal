
#define shaderName input_mouse

#include "Common.h" 

struct InputBuffer {};
initialize() {}

static float distanceToSegment( float2 a, float2 b, float2 p , float2 aspect) {
  float2 pa = p - a, ba = b - a;
  float h = saturate( dot(pa * aspect, ba * aspect ) /dot(ba * aspect, ba * aspect) );
  return length( pa - ba*h );
}

fragmentFn() {
  float3 red = { 1, 0, 0};
  float3 blue = {0, 0, 1};
  float3 yellow = {1, 1, 0};

  float2 p = textureCoord;
  
  float3 col = float3(0.0);
  float2 aspect = uni.iResolution / uni.iResolution.y;

  float2 m = (uni.iMouse - 0.5) * aspectRatio + 0.5;
  float2 lt = (uni.lastTouch - 0.5) * aspectRatio + 0.5;

  if (uni.mouseButtons) {
    float d = distanceToSegment( m , lt, p, aspect );
    col = mix( col, yellow, 1.0-smoothstep(.004,0.008, d) );
    col = mix( col, red , 1.0-smoothstep(0.03,0.035, length((p-m)*aspect) ));
    col = mix( col, blue, 1.0-smoothstep(0.03,0.035, length((p-lt)*aspect) ));
  } else {
    col = mix(0, blue,1.0-smoothstep(0.03,0.035, length((p-m)*aspect) ));
  }
  
  return float4( col, 1.0 );
}
