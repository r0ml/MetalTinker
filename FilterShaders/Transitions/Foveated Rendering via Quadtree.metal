
#define shaderName foveated_rendering_via_quadtree

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) { // mainImage( out float4 o,  float2 U )
  
  float r = 0.1, t = uni.iTime;
  float2 V = textureCoord;
  
  float2 U = textureCoord * aspectRatio;                              // foveated region : disc(P,r)
  float2 P = .5 + .5 * float2(cos(t), sin(t * 0.7)), fU;
  U *= .5; P *= .5;                         // unzoom for the whole domain falls within [0,1]^n
  
  float mipmapLevel = 4.0;
  for (int i = 0; i < 7; ++i) {             // to the infinity, and beyond ! :-)
                                            //fU = min(U,1.-U); if (min(fU.x,fU.y) < 3.*r/H) { o--; break; } // cell border
    if (length(P - float2(0.5)) - r > 0.7) break; // cell is out of the shape
                                                  // --- iterate to child cell
    fU = step(.5, U);                  // select child
    U = 2.0 * U - fU;                    // go to new local frame
    P = 2.0 * P - fU;
    r *= 2.0;
    mipmapLevel -= 0.5;
  }
  float3 col = tex.sample(iChannel0, V, mipmapLevel).rgb;
  return float4(col, 1.) * pow( 32.0 * V.y * V.x * (1.0 - V.y) * (1.0 - V.x), 0.15 );
}
