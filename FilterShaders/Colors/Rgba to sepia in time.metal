
#define shaderName rgba_to_sepia

#include "Common.h" 

constant const float4x4 rgba2sepia =
float4x4
(
0.393, 0.349, 0.272, 0,
0.769, 0.686, 0.534, 0,
0.189, 0.168, 0.131, 0,
0,     0,     0,     1
);

fragmentFn(texture2d<float> tex) {
    float timeFactor = ( 1.0 + sin( uni.iTime ) ) * 0.5;
    float4 color = tex.sample( iChannel0, textureCoord );
    float4x4 rgba2sepiaDiff = float4x4( 1.0 ) + timeFactor * ( rgba2sepia - float4x4( 1.0 ) );
    
    return rgba2sepiaDiff * color;
}
