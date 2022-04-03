
#define shaderName Bars

#include "Common.h" 

constant int N = 11;  // number of final characters
constant float radius = .3;   // radius used above and below mid-height

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = 2 * 6 * (N-1);
  ctrl.instanceCount = 0;
}

vertexFn() {
  VertexOut v;
  
  uint tv = vid % 6; // vertex in quad
  uint tn = vid / 6; // which quad ( there are 2 * (N - 1) quads)
  float g = 1. / (2. * N + 1.);
  float2 b = 0;
  if ( tn < N-1) {
    switch(tv) {
      case 0:
      case 3:
        b.x = (tn / (N + 0.5) ) + g;
        b.y = 0.5;
        break;
      case 1:
        b.x = (tn / (N + 0.5) ) + g;
        b.y = 0.5 - radius * ( (N-tn-1) / float(N) );
        break;
      case 2:
      case 4:
        b.x = (tn / (N + 0.5) ) + 2 * g;
        b.y = 0.5 - radius * ( (N-tn-1) / float(N) );
        break;
      case 5:
        b.x = (tn / (N + 0.5) ) + 2 * g;
        b.y = 0.5;
        break;
    }
  } else {
    float z = (.5+.5*sin(uni.iTime) ) / (N+0.5);
    tn -= N - 1;
    switch(tv) {
      case 0:
      case 3:
        b.x = z + (tn / (N + 0.5) ) + g;
        b.y = 0.5;
        break;
      case 1:
        b.x = z + (tn / (N + 0.5) ) + g;
        b.y = 0.5 + radius * ( (tn + 1)/ (N + 0.5) );
        break;
      case 2:
      case 4:
        b.x = z + (tn / (N + 0.5) ) + 2 * g;
        b.y = 0.5 + radius * ( (tn + 1) / float(N) );
        break;
      case 5:
        b.x = z + (tn / (N + 0.5) ) + 2 * g;
        b.y = 0.5;
        break;
    }
  }
  
  v.where.xy = (2 * b - 1) ;
  v.where.zw = {0, 1};
  v.color = {.9, 0.8, 0.7, 1};
  return v;
}
