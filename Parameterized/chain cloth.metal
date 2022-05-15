
#define shaderName chain_cloth

#include "Common.h"

struct InputBuffer {
    struct {
      int _1;
      int _2;
      int _3;
      int _4;
    } variant;
};

initialize() {
  in.variant._1 = 1;
}


static float r(float2 U, float i, float j, float g) {
  return smoothstep(.06,.0, abs(length(U-float2(i,j))-.85) -.08)* (g);
}

static float4 r(float4 LM, float Ux, float Uy) {
  float l = abs(length(float2(Ux, Uy))-.85);
  float z = smoothstep(.06,.0, l-.08) * (.7+.4*Ux);
  LM.w += 1;
  if (z>LM.y) {
    return float4(l, z, LM.w, LM.w);
  } else {
    return LM;
  }
}

static float W( float2 U ) {
  U = 2.* mod(U*5.,float2(1,1.4)) - float2(1,1.9);           // tiling
  float l = length(U);
  l = U.y/l > -.7 ?  l                                   // loop top = 3/4 ring
  :  length( U - float2 (sign(U.x),-1) );  // loop bottom = 2x half 3/4 ring
  
  // one loop  // thread r= .7 thickness= .2   // pseudo-depth
  return smoothstep(.1,.0, abs(l-.7) -.1) * ( .5+.4*abs(U.y+.6) );    // face A
                                                                      //return smoothstep(.1,.0, abs(l-.7) -.1) * ( 1.-.3*abs(U.y+.6) );    // face B
                                                                      //return abs(l-r);
}

// ==============

fragmentFunc(device InputBuffer &in) {
  float2 U = textureCoord;
  
  if (in.variant._1) {
      U = 2.*fract(U*5.) - 1.;
      return max( max ( r(U,-1,0,1.+U.x) , r (U,1,0,1.-U.x)), max ( r(U,0,-1,  -U.y) , r (U,0,1   ,U.y) ));
  } else if (in.variant._2) {
      U = 2.*fract(U*5.) -1.;

      float4 LM=0.;

      LM = r(LM, U.x+1, U.y);
      LM = r(LM, U.x, U.y);
      LM = r(LM, U.x-1, U.y);
    //    r r r     // offset i = -1, 0, 1    // even lines: tile = 1 circle + 2 half circles

        U.x = -U.x;                          // odd line: horizontal 1/2 offset + symmetry
        U.y -= sign(U.y);

      LM = r(LM, U.x+1, U.y);
      LM = r(LM, U.x, U.y);
      LM = r(LM, U.x-1, U.y);
    //    r r r    // offset i = -1, 0, 1

      return (1.1-LM.x/.1) * LM.y * float4(1,.8,0,1); // tore shading * pseudo-deph * gold
        
  } else if (in.variant._3) {
        float2 V = floor(U*5.);
        U = 2.*fract(U*5.) -1.;

      float4 LM = 0;
      LM = r(LM, U.x+1, U.y);
      LM = r(LM, U.x, U.y);
      LM = r(LM, U.x-1, U.y);

     //   r r r     // offset i = -1, 0, 1    // even lines: tile = 1 circle + 2 half circles

        U.x = -U.x;                          // odd line: horizontal 1/2 offset + symmetry
      U.y -= sign(U.y);
      
      LM = r(LM, U.x+1, U.y);
      LM = r(LM, U.x, U.y);
      LM = r(LM, U.x-1, U.y);

    //    r r r    // offset i = -1, 0, 1

        // --- coloring
        // V = tile number , L = ring number in tile.  attention: odd lines are split upon tiles
        V *= 2.;
        if (LM.z > 3.)  V.x -= LM.z-5.,              // reconnect sides  half-rings of odd lines
                     V.y -= sign(U.y);         // reconnect up/down half-rings of odd lines
            else     V.x += LM.z-2.;              // reconnect sides  half-rings of even lines
      
      float2 r1 = rand2( V+float2(.1,.2));
      float2 r2 = rand2( V+ LM.z/9.);
      return LM.y * float4( r1.x, r1.y, r2.x, r2.y );
  } else if (in.variant._4) {
    float4 fragColor = max( W(U), W( U+float2(0,.7) ) ) ; // inter-weaving
    fragColor.x==W(U) ? fragColor.bg*=.8 : fragColor.rg *= .8; // color ( + 28 chars)
    return fragColor;
  }
  return 0;
}
