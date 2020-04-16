
#define shaderName Bars

#include "Common.h" 

constant int N = 11;  // number of final characters
constant float radius = .3;   // radius used above and below mid-height

struct KBuffer {
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  kbuff.pipeline._1 = {3, (N-1) * 2 * 6, 1, 0};
}

vertexFn(_1) {
  VertexOut v;
  
  uint tv = vid % 6; // vertex in quad
  uint tn = vid / 6; // which quad ( there are 2 * (N - 1) quads)
  float g = 1. / (2. * N + 1.);
  if ( tn < N-1) {
    switch(tv) {
      case 0:
      case 3:
        v.barrio.x = (tn / (N + 0.5) ) + g;
        v.barrio.y = 0.5;
        break;
      case 1:
        v.barrio.x = (tn / (N + 0.5) ) + g;
        v.barrio.y = 0.5 - radius * ( (N-tn-1) / float(N) );
        break;
      case 2:
      case 4:
        v.barrio.x = (tn / (N + 0.5) ) + 2 * g;
        v.barrio.y = 0.5 - radius * ( (N-tn-1) / float(N) );
        break;
      case 5:
        v.barrio.x = (tn / (N + 0.5) ) + 2 * g;
        v.barrio.y = 0.5;
        break;
    }
  } else {
    float z = (.5+.5*sin(uni.iTime) ) / (N+0.5);
    tn -= N - 1;
    switch(tv) {
      case 0:
      case 3:
        v.barrio.x = z + (tn / (N + 0.5) ) + g;
        v.barrio.y = 0.5;
        break;
      case 1:
        v.barrio.x = z + (tn / (N + 0.5) ) + g;
        v.barrio.y = 0.5 + radius * ( (tn + 1)/ (N + 0.5) );
        break;
      case 2:
      case 4:
        v.barrio.x = z + (tn / (N + 0.5) ) + 2 * g;
        v.barrio.y = 0.5 + radius * ( (tn + 1) / float(N) );
        break;
      case 5:
        v.barrio.x = z + (tn / (N + 0.5) ) + 2 * g;
        v.barrio.y = 0.5;
        break;
    }
  }
  
  v.barrio.zw = {0, 1};

  v.where.xy = (2 * v.barrio.xy - 1) ;
  v.where.zw = {0, 1};
  v.color = {.9, 0.8, 0.7, 1};
  return v;
}
