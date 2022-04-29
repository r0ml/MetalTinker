/** 
Author: TinyTexel
variation of https://www.shadertoy.com/view/XlfyWl

*/
#define shaderName BloOoOoOoOoOom

#include "Common.h"

// BloOoOoOoOoOom
// by TinyTexel
// Creative Commons Attribution-ShareAlike 4.0 International Public License

/*
variation of https://www.shadertoy.com/view/XlfyWl
*/

#define Time uni.iTime
#define PixelCount uni.iResolution.xy
#define clamp01(x) saturate(x)



 // BloOoOoOoOoOom
// by TinyTexel
// Creative Commons Attribution-ShareAlike 4.0 International Public License

/*
variation  of https://www.shadertoy.com/view/XlfyWl
*/

#define SPOT_COUNT_MUL 12.0

// #define USE_SSAA

///////////////////////////////////////////////////////////////////////////
//=======================================================================//

#define Time uni.iTime
#define PixelCount uni.iResolution.xy
#define OUT

#define rsqrt inversesqrt
#define clamp01(x) saturate(x)


class shaderName {
public:

  const float Pi05 = PI * 0.5;

float Pow2(float x) {return x*x;}
float Pow3(float x) {return x*x*x;}
float Pow4(float x) {return Pow2(Pow2(x));}

float2 AngToVec(float ang)
{	
	return float2(cos(ang), sin(ang));
}


float SqrLen(float v) {return v * v;}
float SqrLen(float2  v) {return dot(v, v);}
float SqrLen(float3  v) {return dot(v, v);}
float SqrLen(float4  v) {return dot(v, v);}

#define If(cond, tru, fls) mix(fls, tru, cond)
//=======================================================================//
///////////////////////////////////////////////////////////////////////////

#define FUNC4_UINT(f)								\
uint2 f(uint2 v) {return uint2(f(v.x ), f(v.y ));}	\
uint3 f(uint3 v) {return uint3(f(v.xy), f(v.z ));}	\
uint4 f(uint4 v) {return uint4(f(v.xy), f(v.zw));}	\
    

// single iteration of Bob Jenkins' One-At-A-Time hashing algorithm:
//  http://www.burtleburtle.net/bob/hash/doobs.html
// suggestes by Spatial on stackoverflow:
//  http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
uint BJXorShift(uint x) 
{
    x += x << 10u;
    x ^= x >>  6u;
    x += x <<  3u;
    x ^= x >> 11u;
    x += x << 15u;
	
    return x;
}

FUNC4_UINT(BJXorShift)    
    

// xor-shift algorithm by George Marsaglia
//  https://www.thecodingforums.com/threads/re-rngs-a-super-kiss.704080/
// suggestes by Nathan Reed:
//  http://www.reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
uint GMXorShift(uint x)
{
    x ^= x << 13u;
    x ^= x >> 17u;
    x ^= x <<  5u;
    
    return x;
}

FUNC4_UINT(GMXorShift) 
    
// hashing algorithm by Thomas Wang 
//  http://www.burtleburtle.net/bob/hash/integer.html
// suggestes by Nathan Reed:
//  http://www.reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
uint WangHash(uint x)
{
    x  = (x ^ 61u) ^ (x >> 16u);
    x *= 9u;
    x ^= x >> 4u;
    x *= 0x27d4eb2du;
    x ^= x >> 15u;
    
    return x;
}

FUNC4_UINT(WangHash) 
    
//#define Hash BJXorShift
#define Hash WangHash
//#define Hash GMXorShift

// "floatConstruct"          | renamed to "ConstructFloat" here 
// By so-user Spatial        | http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
// reformatted and changed from original to extend interval from [0..1) to [-1..1) 
//-----------------------------------------------------------------------------------------
// Constructs a float within interval [-1..1) using the low 23 bits + msb of an uint.
// All zeroes yields -1.0, all ones yields the next smallest representable value below 1.0. 
float ConstructFloat(uint m) 
{
	float flt = as_type<float>( (m & 0x007FFFFFu) | 0x3F800000u);// [1..2)
    float sub = (m >> 31u) == 0u ? 2.0 : 1.0;
    
    return flt - sub;// [-1..1)             
}

float2 ConstructFloat(uint2 m) { return float2(ConstructFloat(m.x), ConstructFloat(m.y)); }
float3 ConstructFloat(uint3 m) { return float3(ConstructFloat(m.xy), ConstructFloat(m.z)); }
float4 ConstructFloat(uint4 m) { return float4(ConstructFloat(m.xyz), ConstructFloat(m.w)); }


uint Hash(uint  v, uint  r) { return Hash(v ^ r); }
uint Hash(uint2 v, uint2 r) { return Hash(Hash(v.x , r.x ) ^ (v.y ^ r.y)); }
uint Hash(uint3 v, uint3 r) { return Hash(Hash(v.xy, r.xy) ^ (v.z ^ r.z)); }
uint Hash(uint4 v, uint4 r) { return Hash(Hash(v.xy, r.xy) ^ Hash(v.zw, r.zw)); }

// Pseudo-random float value in interval [-1:1).
float Hash(float v, uint  r) { return ConstructFloat(Hash(as_type<uint>(v), r)); }
float Hash(float2  v, uint2 r) { return ConstructFloat(Hash(as_type<uint2>(v), r)); }
float Hash(float3  v, uint3 r) { return ConstructFloat(Hash(as_type<uint3>(v), r)); }
float Hash(float4  v, uint4 r) { return ConstructFloat(Hash(as_type<uint4>(v), r)); }


float HashFlt(uint   v, uint  r) { return ConstructFloat(Hash(v, r)); }
float HashFlt(uint2  v, uint2 r) { return ConstructFloat(Hash(v, r)); }
float HashFlt(uint3  v, uint3 r) { return ConstructFloat(Hash(v, r)); }
float HashFlt(uint4  v, uint4 r) { return ConstructFloat(Hash(v, r)); }

uint HashUInt(float v, uint  r) { return Hash(as_type<uint>(v), r); }
uint HashUInt(float2  v, uint2 r) { return Hash(as_type<uint2>(v), r); }
uint HashUInt(float3  v, uint3 r) { return Hash(as_type<uint3>(v), r); }
uint HashUInt(float4  v, uint4 r) { return Hash(as_type<uint4>(v), r); }



///////////////////////////////////////////////////////////////////////////
//=======================================================================//
#if 0
// shoulder of the s-curve
float SCurveU_Sh(float x)
{
    float a = x < 0.25 ?   0.0        :
              x < 0.5  ? - 1.0 / 60.0 :
              x < 0.75 ?  47.0 / 60.0 :
                         -49.0 / 15.0 ;
    
    float b = x < 0.25 ?   2.0        :
              x < 0.5  ?   7.0 /  3.0 :
              x < 0.75 ? -17.0 /  3.0 :
                          64.0 /  3.0 ; 

    float c = x < 0.25 ?   0.0        :
              x < 0.5  ? - 8.0 /  3.0 :
              x < 0.75 ?  88.0 /  3.0 :
                         -128.0/  3.0 ; 

    float d = x < 0.25 ?   0.0        :
              x < 0.5  ?  32.0 /  3.0 :
              x < 0.75 ? -160.0/  3.0 :
                          128.0/  3.0 ; 
    
    float e = x < 0.25 ?   0.0        :
              x < 0.5  ? -64.0 /  3.0 :
              x < 0.75 ?  128.0/  3.0 :
                         -64.0 /  3.0 ;    
    
    float f = x < 0.25 ? -64.0 / 15.0 :
              x < 0.5  ?  64.0 /  5.0 :
              x < 0.75 ? -64.0 /  5.0 :
                          64.0 / 15.0 ;  
    
    float r = a + x*(b + x*(c + x*(d + x*(e + x*f))));   
    
    return r;
}

// s-curve [-1..1]
float SCurveU(float x)
{
   float s = x < 0.0 ? -1.0 : 1.0;
    
   return SCurveU_Sh(abs(x)) * s;
}

float Noise(float2 uv, float time, uint3 seed)
{       
    uv = uv * float2(0.97617, 1.38559) + float2(0.93792, 0.77608);// diffusion
    time = time * 1.17739 + 0.62852;
    
    return Hash(float3(uv, time), seed);  
}

float BNoise(float2 uv, float time, uint3 seed)
{    
    float v  = Noise(uv, time, seed);
    
    float v0 = Noise(uv + float2(-1.0, 0.0), time, seed);
    float v1 = Noise(uv + float2( 1.0, 0.0), time, seed);
    float v2 = Noise(uv + float2( 0.0,-1.0), time, seed);
    float v3 = Noise(uv + float2( 0.0, 1.0), time, seed);
      
    float vf = (v0+v1+v2+v3) * 0.125 + v * -0.5;    
    
    vf = SCurveU(vf);
    
    return vf;// return v to get white noise for comparison 
}
#endif

/*
IN:
	rp		: ray start position
	rd		: ray direction (normalized)
	
	sp2		: sphere position
	sr2		: sphere radius squared
	
OUT:
	t		: distances to intersection points (negative if in backwards direction)

EXAMPLE:	
	float2 t;
	float hit = Intersect_Ray_Sphere(pos, dir, float3(0.0), 1.0, OUT t);
*/
float Intersect_Ray_Sphere(
float3 rp, float3 rd, 
float3 sp, float sr2, 
thread float2& t)
{	
	rp -= sp;
	
	float a = dot(rd, rd);
	float b = 2.0 * dot(rp, rd);
	float c = dot(rp, rp) - sr2;
	
	float D = b*b - 4.0*a*c;
	
	if(D < 0.0) return 0.0;
	
	float sqrtD = sqrt(D);
	// t = (-b + (c < 0.0 ? sqrtD : -sqrtD)) / a * 0.5;
	t = (-b + float2(-sqrtD, sqrtD)) / a * 0.5;
	
	// if(start == inside) ...
	if(c < 0.0) t.xy = t.yx;

	// t.x > 0.0 || start == inside ? infront : behind
	return t.x > 0.0 || c < 0.0 ? 1.0 : -1.0;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////
//=================================================================================================//
// Spherical Fibonacci Mapping
// http://lgdv.cs.fau.de/publications/publication/Pub.2015.tech.IMMD.IMMD9.spheri/
// Authors: Benjamin Keinert, Matthias Innmann, Michael Sänger, Marc Stamminger
// (code copied from: https://www.shadertoy.com/view/4t2XWK)
//-------------------------------------------------------------------------------------------------//

const float PHI = 1.6180339887498948482045868343656;

float madfrac( float a,float b) { return a*b -floor(a*b); }
float2  madfrac( float2 a, float b) { return a*b -floor(a*b); }

float sf2id(float3 p, float n) 
{
    float phi = min(atan2(p.y, p.x), PI), cosTheta = p.z;
    
    float k  = max(2.0, floor( log(n * PI * sqrt(5.0) * (1.0 - cosTheta*cosTheta))/ log(PHI*PHI)));
    float Fk = pow(PHI, k)/sqrt(5.0);
    
    float2 F = float2( round(Fk), round(Fk * PHI) );

    float2 ka = -2.0*F/n;
    float2 kb = 2.0*PI*madfrac(F+1.0, PHI-1.0) - 2.0*PI*(PHI-1.0);    
    float2x2 iB = float2x2( ka.y, -ka.x, -kb.y, kb.x ) * float2x2( 1/(ka.y*kb.x - ka.x*kb.y));

    float2 c = floor( iB * float2(phi, cosTheta - (1.0-1.0/n)));
    float d = 8.0;
    float j = 0.0;
    for( int s=0; s<4; s++ ) 
    {
        float2 uv = float2( float(s-2*(s/2)), float(s/2) );
        
        float cosTheta = dot(ka, uv + c) + (1.0-1.0/n);
        
        cosTheta = clamp(cosTheta, -1.0, 1.0)*2.0 - cosTheta;
        float i = floor(n*0.5 - cosTheta*n*0.5);
        float phi = 2.0*PI*madfrac(i, PHI-1.0);
        cosTheta = 1.0 - (2.0*i + 1.)/n;
        float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
        
        float3 q = float3( cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta);
        float squaredDistance = dot(q-p, q-p);
        if (squaredDistance < d) 
        {
            d = squaredDistance;
            j = i;
        }
    }
    return j;
}

float3 id2sf( float i, float n) 
{
    float phi = 2.0*PI*madfrac(i,PHI);
    float zi = 1.0 - (2.0*i+1.)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return float3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}
//=================================================================================================//
/////////////////////////////////////////////////////////////////////////////////////////////////////


/*
ProjSphereArea - returns the screen space area of the projection of a sphere (assuming its an ellipse)

IN:
	rdz- z component of the unnormalized ray direction in camera space
	p  - center position of the sphere in camera space
	rr - squared radius of the sphere

"Sphere - projection" code used under
*/
float ProjSphereArea(float rdz, float3 p, float rr)
{
	float zz = p.z * p.z;	
	float ll = dot(p, p);
	
	//return Pi * rdz*rdz * rr * sqrt(abs((rr - ll) / (zz - rr))) / (zz - rr);
    return PI * rdz*rdz * rr * rsqrt(abs(Pow3(rr - zz) / (rr - ll)));
}

// https://www.shadertoy.com/view/XtfyWs
float4 ProjDisk(float3 rd, float3 p, float3 n, float rr)
{   
    float3 np0 = n * p.xyz;
    float3 np1 = n * p.yzx;
    float3 np2 = n * p.zxy;  

    float3x3 k_mat = float3x3(float3( np0.y + np0.z,  np2.x        ,  np1.x        ),
						  float3(-np2.y        ,  np1.y        , -np0.x - np0.z),
						  float3(-np1.z        , -np0.x - np0.y,  np2.z        ));    
    
    float3 u =     k_mat * rd;
    float3 k = u * k_mat;
    
    
    float nrd = dot(n, rd);
    
    float nrd_rr = nrd * rr;

    
    float v = dot(u, u) - nrd * nrd_rr; 
    float3  g =    (k     - n   * nrd_rr) * 2.0;   
    
    return float4(g.xy, 0.0, v);
}



float Sph(float x, float rr) { return sqrt(rr - x*x); }
float SphX0(float d, float rr0, float rr1) { return 0.5 * (d + (rr0 - rr1) / d); }

float3 EvalSceneCol(float3 cpos, float3x3 cam_mat, float focalLen, float2 uv0, float time, float2 pc)
{      
    const float3 cBG = 0.0 * float3(0.9, 1.0, 1.2);

        
    float2 uv2 = uv0 - pc * 0.5;
    
  	float3 rdir0 = float3(uv2, focalLen);
    
    float rdir0S = 0.5 * pc.x;
    rdir0 /= rdir0S;
    
    float3 rdir = normalize(cam_mat * rdir0); 
    
    
    float2 t;
	float hit = Intersect_Ray_Sphere(cpos, rdir, float3(0.0), 1.0, OUT t);
    
    if(hit <= 0.0) return cBG;


    float3 pf = cpos + rdir * t.x;
//    float3 pb = cpos + rdir * t.y;

	float3 col = cBG;

    //float lerpF = 0.0;
    
    float rra = 0.0;

    float3 p2;
    float rr;
    {
        const float s = SPOT_COUNT_MUL; //       SPOT_COUNT_MUL
        const float n = 1024.0*s;

        float id = sf2id(pf.xzy, n);
              p2 = id2sf(id,     n).xzy;        

        float u = id / n;
       
        float arg = (-u* 615.5*2.0*s) + time * 1.0;//238-3 384.-2 615-1

        rra = sin(arg);

        #if 1    
        //for(float i = 0.0; i < 2.0; ++i)        
        rra = (Pow2(rra)*2.-1.);
        #endif

        rra = Pow2(rra);        

        rr = 0.0025/s * rra; 
    }
    
    
    float3 n2 = normalize(p2);
    
    const float maskS = 0.5;// sharpness

    
    if(SqrLen(pf - p2) > rr) return cBG;

    float d = length(p2);

    float x0 = SphX0(d, 1.0, rr);        
    float3 d0c = n2 * x0;

    float d0rr = 1.0 - x0*x0;

    float3 dp_c = (d0c - cpos) * cam_mat;
    float3 dn_c = n2 * cam_mat;

    float4 r = ProjDisk(rdir0, dp_c, dn_c, d0rr);        

    float cmask = clamp01(-r.w * rsqrt(dot(r.xy, r.xy))*rdir0S * maskS);

    float cmask2 = 0.0;
    {
        float3 d1c = n2 * (x0 - 0.008);

        float4 r = ProjDisk(rdir0, (d1c - cpos) * cam_mat, n2 * cam_mat, (1.0 - x0*x0)*rra);
        cmask2 = clamp01(-r.w * rsqrt(dot(r.xy, r.xy))*rdir0S * maskS);
    }


    #if 1	
    float A = ProjSphereArea(rdir0.z, dp_c, d0rr);        
    A *= rdir0S*rdir0S;

    float NdV = abs(dot(dn_c, normalize(dp_c)));

    A *= NdV;
    
    #ifndef USE_SSAA
    A *= NdV;
    cmask *= clamp01((A -2.0)*0.125);
    #else
    A = mix(A, A*NdV, 0.5);
    cmask *= clamp01((A - 3.)*0.125);
    #endif


    #endif


    const float3 cB = float3(0.1, 0.35, 1.0);
//    const float3 cR = float3(1., 0.02, 0.2);

    //float3 cX = mix(cB, cR, lerpF);
    //float3 cY = mix(cR, cB, lerpF);

    return mix(cBG, mix(cB*1.2, float3(0.4, -0.15, -0.05), cmask2), cmask);        
    //return mix(cBG, mix(cR, cB, cmask2), cmask);
    //return mix(cBG, mix(cX, cY, cmask2), cmask);        
    //return mix(cBG, mix(cW, cX, cmask2), cmask);
    //return mix(cBG, float3(1.0), cmask);
    //return float3(-r.w*10.0);
    //return float3(1.0);
    
    return col;
}

};


fragmentFn(texture2d<float> lastFrame) {
  shaderName shad;

  float3 col = float3(0.0);
    
    float2 uv = thisVertex.where.xy.xy - 0.5;
  
    float time = Time; 
    //float noise0 = BNoise(uv, Time, uint3(0x3824E65Cu, 0xDE74DC07u, 0x779899B8u));
    //float noise1 = BNoise(uv, Time, uint3(0xF41058FCu, 0xEA297D0Au, 0xC0EE8F01u));
    //float noise = noise0 * 0.5;
    //noise = (noise0 + noise1) * 0.5;
    float noise = shad.Hash(float3(uv, Time) * 0.435 + 0.847, uint3(0x0D5B3B33u, 0x1451393Cu, 0x29176787u)) * 0.5;
    
    time += uni.iTimeDelta * noise;
    //float4 mouseAccu = texelFetch(iChannel0, int2(1, 0), 0); 

    float2 ang = float2(PI * 0.0, -PI * 0.3);
    //ang += mouseAccu.xy * 0.008;

    #if 1
    ang.x += time * 0.15*1.5;
    ang.y += sin(time * 0.27 * PI) * 0.1;
    
    //ang.y += time * 0.073;
    #endif

    float fov = PI * 0.5;
    
    float3x3 cam_mat;
    float focalLen;
    {
        float sinPhi   = sin(ang.x);
        float cosPhi   = cos(ang.x);
        float sinTheta = sin(ang.y);
        float cosTheta = cos(ang.y);    

        float3 front = float3(cosPhi * cosTheta, 
                                   sinTheta, 
                          sinPhi * cosTheta);

        float3 right = float3(-sinPhi, 0.0, cosPhi);
        float3 up    = cross(right, front);

        focalLen = PixelCount.x * 0.5 * tan(shad.Pi05 - fov * 0.5);
        
        cam_mat = float3x3(right, up, front);
    }
    
    //float3 cpos = -cam_mat[2] * (exp2(-0.3 + mouseAccu.w * 0.03));
    float3 cpos = -cam_mat[2] * (exp2(-0.3));

    cpos.y += .75;
    cpos.y += cos(time * 0.153 * PI) * 0.08;
    
    #ifndef USE_SSAA
    
	col = shad.EvalSceneCol(cpos, cam_mat, focalLen, thisVertex.where.xy, time, PixelCount);
    
	#elif 1
    
    col  = EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.3, 0.1));
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.9, 0.3));
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.5, 0.5));
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.1, 0.7));
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.7, 0.9));   
    col *= 0.2;
    
 	#elif 1
    
    float o = 1.;
    col  = EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.3, 0.1) * o - 0.5*o+0.5) * float3(1.5, 0.75, 0.0);
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.9, 0.3) * o - 0.5*o+0.5) * float3(0.0, 0.0, 3.0);
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.5, 0.5) * o - 0.5*o+0.5) * float3(0.0, 3.0, 0.0);
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.1, 0.7) * o - 0.5*o+0.5) * float3(3.0, 0.0, 0.0);
    col += EvalSceneCol(cpos, cam_mat, focalLen, uv + float2(0.7, 0.9) * o - 0.5*o+0.5) * float3(0.0, 0.75, 1.5);   
    
    col /= float3(4.5, 4.5, 4.5);

    #endif


    
    #if 1
    float2 tex = thisVertex.where.xy.xy / PixelCount;
    float2 o = .0006 * float2(1., PixelCount.x / PixelCount.y);
    float h = shad.Hash(float3(uv, Time) * 0.435 + 0.847, uint3(0xB5701DB5u, 0xDB985643u, 0x2063262Fu));
    float2 od = shad.AngToVec(h * PI);
    //od = float2(rsqrt(2.0));
    
//    float3 c0 = textureLod(renderPass[0],iChannel0, tex, 0.0).rgb;
    float3 c1 = textureLod(lastFrame,iChannel0, tex + o * float2( od.x, od.y) , 0.0).rgb;
    float3 c2 = textureLod(lastFrame,iChannel0, tex + o * float2(-od.y, od.x) , 0.0).rgb;
    float3 c3 = textureLod(lastFrame,iChannel0, tex + o * float2( od.y,-od.x) , 0.0).rgb;
    float3 c4 = textureLod(lastFrame,iChannel0, tex + o * float2(-od.x,-od.y) , 0.0).rgb;
    
    float3 cc = (c1 + c2 + c3 + c4) * 0.25;
    
    col *= 8.;
    col = mix(cc, col, uni.iTimeDelta / (uni.iTimeDelta + 1.));
    //col = col * 0.2  + c0 * 0.95;
    //col =cc;
    #endif
    
    return float4(col, 0.);
	//outCol = float4(gammaEncode(clamp01(col)), 1.0);
}
