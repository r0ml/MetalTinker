
#define shaderName flip

#include "Common.h" 

struct InputBuffer {
  int3 slices;
  float3 rspeed;
};

initialize() {
  in.slices = {3, 10, 20};
  in.rspeed = {10, 30, 100};
}

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1, device InputBuffer& in ) {
  float2 uv = textureCoord;
  float perWidth = 1.0 / in.slices.y;
  float index = floor( uv.x / perWidth );
  float centerX = perWidth * ( index + 0.5 );
  float left = perWidth * index;
  float right = left + perWidth;
  float angle = mod(scn_frame.time * in.rspeed.y, 2 * PI);

  float2 cod = float2( ( uv.x - centerX) / cos( angle ) + centerX, uv.y );
  
  if( cod.x <= right && cod.x >= left ) {
    if (angle >= PI/2 && angle <= 3 * PI / 2) {
      return tex1.sample( iChannel0, float2( right - cod.x + left, cod.y ) );
    } else {
      return tex0.sample( iChannel0, cod);
    }
  } else {
    return float4( float3( 0.0 ), 1.0 );   
  }
}


