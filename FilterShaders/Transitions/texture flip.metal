
#define shaderName texture_flip

#include "Common.h" 

struct InputBuffer {
};

initialize() {
//  setTex(0, asset::bubbles);
//  setTex(1, asset::london);
}


constant const float perWidth = 0.1;
constant const float rspeed = 10.5;

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;
  
  float index = floor( uv.x / perWidth );
  float centerX = perWidth * ( index + 0.5 );
  float left = perWidth * index;
  float right = left + perWidth;
  
  float perRotateTime = PI / rspeed;
  float startRotateTime = perRotateTime * 0.5 * index;
  float endRotateTime = startRotateTime + perRotateTime;
  
  float angle = (uni.iTime - startRotateTime) * rspeed;
  float2 cod = float2(( uv.x - centerX) / cos( angle ) + centerX, uv.y );
  
  if( uni.iTime <= startRotateTime ) {
    return tex0.sample( iChannel0, uv );
  }
  else if( uni.iTime > endRotateTime ) {
    return tex1.sample( iChannel0, uv );
  }
  else if( cod.x <= right && cod.x >= left ) {
    if( angle <= 1.5707 ) {
      return tex0.sample( iChannel0, cod );
    } else if( angle <= PI ) {
      return tex1.sample( iChannel0, float2( right - cod.x + left, cod.y ) );
    }
  } else {
    return float4( float3( 0.0 ), 1.0 );   
  }
  return 0;
}


