
#define shaderName Entanglement

#include "Common.h"

static float trig( float dist, float decay, float frequency, float amplitude, float speed, float time ) {
  return exp(-decay * dist) * sin(dist * frequency + ((time) * speed)) * amplitude;
}

fragmentFunc(constant float2& mouse) {
  float2 uv = textureCoord;
  float2 m = mouse;
  float t = scn_frame.time;
  float freq = (50.0);
  float ampl = 2.1;
  float2 center = m;
  float n = .3;
  float2 cir = float2( 0.7 + n * sin( t ), 0.5 + n * cos( t ) );
  float2 centerOne = float2( cir.x, cir.y );
  float dist = length(uv - center);
  float distOne = length(uv - centerOne);
  float decay = 5.8;
  float trigger = dist * distOne;
  float speed = 2.0;
  float triggy = 0.0;

  // float maxiter = 5.0;
  triggy = trig(trigger, decay, freq, ampl, speed, t);
  
  float colourer = mix( triggy*t,0.2, 1.0 );
  float3 rgb = float3( min( triggy, colourer), min( triggy, colourer ), min( triggy, colourer ) );
  return float4( triggy, rgb );
}
