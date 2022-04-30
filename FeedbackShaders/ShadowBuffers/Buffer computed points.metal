
#define shaderName Buffer_computed_points

#include "Common.h"


typedef struct {
  float2 position[128];
  float velocity[128];
  float seed[128];
} MyBuffer;


frameInitialize( device MyBuffer& velo ) {
  for(int y = 0; y < 128; y ++) {
    if (uni.iFrame == 0) {
      // initial position
      velo.position[y] = float2(0, rand( float2(y/128.0, 0)  ) - 2);

      float2 winCoord = float2(0, y);
      // initial speed vector

      velo.velocity[y] = rand(winCoord * velo.position[y]) - 0.5;

      velo.seed[y] = rand(velo.position[y] * 1000.+ uni.iDate.w * 100.) - 0.5;

    } else {

      float2 C = velo.position[y] ;
      float V = velo.velocity[y] ;
      float S = velo.seed[y] ;

      S -= 0.2;

      if (abs(C.x) > 1) {
        V = -V;
      }

      if (C.y < -1) {
        S = -S;
      }

      if (C.y > 1) {
        S = -1;
      }

      C += float2(V, S) * 0.02;

      velo.position[y] = C ;
      velo.velocity[y] = V ;
      velo.seed[y] = S ;
    }
  }
}


fragmentFn(device MyBuffer &velo) {

  float2 uv = worldCoordAspectAdjusted;
  float4 fragColor = 0;

  for (int y = 0; y < 128; y++) {
    float2 c = velo.position[y];
    float2 d = abs(c / 2 + 0.5);

    float cc = velo.velocity[y] + 0.5;
    fragColor = mix(fragColor, float4(d.x, d.y, abs(cc), d.x) , smoothstep(0., 1., 1. / length(uv -  c ) * .015));
  }
  return fragColor;

}

