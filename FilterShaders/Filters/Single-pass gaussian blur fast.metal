
#define shaderName single_pass_gaussian_blur_fast

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const int samples = 35,
LOD = 2,         // gaussian done on MIPmap at scale LOD
sLOD = 1 << LOD; // tile size = 2^LOD
constant const float sigma = float(samples) * .25;

static float gaussian(float2 i) {
  float2 ii = i/sigma;
  return exp( -.5* dot(ii,ii) ) / ( TAU * sigma*sigma );
}

static float4 blur(texture2d<float> sp, float2 U, float2 scale) {
  float4 O = float4(0);
  int s = samples/sLOD;

  for ( int i = 0; i < s*s; i++ ) {
    float2 d = float2(i%s, i/s)*float(sLOD) - float(samples)/2.;
    O += gaussian(d) * textureLod( sp, iChannel0, U + scale * d , float(LOD) );
  }

  return O / O.a;
}

fragmentFn(texture2d<float> tex) {
  return blur( tex, textureCoord, 1./textureSize(tex) );
}
