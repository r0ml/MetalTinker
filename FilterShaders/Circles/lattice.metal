
#define shaderName lattice

#include "Common.h" 

fragmentFn() {
  float4 fragColor = 0;
  for (float i=.1; i<1.01; i+=.1) {
    //              lattice                                      color
      fragColor += step(.47, length( fract( 10 * textureCoord * aspectRatio/i - uni.iTime * i ) -.5 )) * (i - fragColor);
  }

  return fragColor;
}
