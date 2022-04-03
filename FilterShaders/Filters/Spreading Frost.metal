
#define shaderName Spreading_Frost

#include "Common.h"

#define FROSTYNESS 0.5
//#define RANDNERF 2.5

fragmentFn(texture2d<float> tex0, texture2d<float> tex1, texture2d<float> tex2) {
  float2 uv = textureCoord;
    float progress = fract(uni.iTime / 4.0);

    float4 frost = tex1.sample(iChannel0, uv);
    float icespread = tex2.sample(iChannel0, uv).r;

    float2 rnd = float2(rand(uv+frost.r*0.05), rand(uv+frost.b*0.05));
            
    float size = mix(progress, sqrt(progress), 0.5);   
    size = size * 1.12 + 0.0000001; // just so 0.0 and 1.0 are fully (un)frozen and i'm lazy
    
    float2 lens = float2(size, pow(size, 4.0) / 2.0);
    float dist = distance(uv.xy, float2(0.5, 0.5)); // the center of the froziness
    float vignette = pow(1.0-smoothstep(lens.x, lens.y, dist), 2.0);
   
    rnd *= frost.rg*vignette*FROSTYNESS;
    
    rnd *= 1.0 - floor(vignette); // optimization - brings rnd to 0.0 if it won't contribute to the image
    
    float4 regular = tex0.sample(iChannel0, uv);
    float4 frozen = tex0.sample(iChannel0, uv + rnd);
    frozen *= float4(0.9, 0.9, 1.1, 1.0);
        
    return mix(frozen, regular, smoothstep(icespread, 1.0, pow(vignette, 2.0)));
}
