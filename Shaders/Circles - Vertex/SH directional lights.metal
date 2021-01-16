
#define shaderName SH_directional_lights

#include "Common.h"

struct InputBuffer {
  bool OPTIMIZED = true;
};

initialize() { }
//
// slow version, but true to the mathematical formulation
//
static void SH_AddLightDirectionalSlow( const float3 col, const float3 v, thread float3 * sh )
{
    #define NO  1.0        // for perfect overal brigthness match
  //#define NO (16.0/17.0) // for normalizing to maximum = 1.0;
    sh[0] += col * (NO*PI*1.000) * (0.50*sqrt( 1.0/PI));
    sh[1] += col * (NO*PI*0.667) * (0.50*sqrt( 3.0/PI)) * v.x;
    sh[2] += col * (NO*PI*0.667) * (0.50*sqrt( 3.0/PI)) * v.y;
    sh[3] += col * (NO*PI*0.667) * (0.50*sqrt( 3.0/PI)) * v.z;
    sh[4] += col * (NO*PI*0.250) * (0.50*sqrt(15.0/PI)) * v.x*v.z;
    sh[5] += col * (NO*PI*0.250) * (0.50*sqrt(15.0/PI)) * v.z*v.y;
    sh[6] += col * (NO*PI*0.250) * (0.50*sqrt(15.0/PI)) * v.y*v.x;
    sh[7] += col * (NO*PI*0.250) * (0.25*sqrt( 5.0/PI)) * (3.0*v.z*v.z-1.0);
    sh[8] += col * (NO*PI*0.250) * (0.25*sqrt(15.0/PI)) * (v.x*v.x-v.y*v.y);
}

static float3 SH_EvalulateSlow( const float3 v, const float3 sh[9] )
{
    return sh[0] * (0.50*sqrt( 1.0/PI)) +
           sh[1] * (0.50*sqrt( 3.0/PI)) * v.x +
           sh[2] * (0.50*sqrt( 3.0/PI)) * v.y +
           sh[3] * (0.50*sqrt( 3.0/PI)) * v.z +
           sh[4] * (0.50*sqrt(15.0/PI)) * v.x*v.z +
           sh[5] * (0.50*sqrt(15.0/PI)) * v.z*v.y +
           sh[6] * (0.50*sqrt(15.0/PI)) * v.y*v.x +
           sh[7] * (0.25*sqrt( 5.0/PI)) * (3.0*v.z*v.z-1.0) +
           sh[8] * (0.25*sqrt(15.0/PI)) * (v.x*v.x-v.y*v.y);
}

//
// fast version, premultiplied components and simplified terms
//
void SH_AddLightDirectionalOpt( const float3 col, const float3 v, thread float3 * sh )
{
     #define DI 64.0  // for perfect overal brigthness match
   //#define DI 68.0  // for normalizing to maximum = 1.0;
	
	sh[0] += col * (21.0/DI);
	sh[0] -= col * (15.0/DI) * v.z*v.z;
	sh[1] += col * (32.0/DI) * v.x;
	sh[2] += col * (32.0/DI) * v.y;
	sh[3] += col * (32.0/DI) * v.z;
	sh[4] += col * (60.0/DI) * v.x*v.z;
	sh[5] += col * (60.0/DI) * v.z*v.y;
	sh[6] += col * (60.0/DI) * v.y*v.x;
	sh[7] += col * (15.0/DI) * (3.0*v.z*v.z-1.0);
	sh[8] += col * (15.0/DI) * (v.x*v.x-v.y*v.y);
}

/*
void SH_AddDome( thread float3& sh[9], const float3 colA, const float3 colB )
{
	sh[0] += 0.5*(colB + colA);
	sh[2] += 0.5*(colB - colA);
}
*/

static float3 SH_EvalulateOpt( const float3 v, const float3 sh[9] )
{
	return sh[0] +
           sh[1] * v.x +
           sh[2] * v.y +
           sh[3] * v.z +
           sh[4] * v.x*v.z +
           sh[5] * v.z*v.y +
           sh[6] * v.y*v.x +
           sh[7] * v.z*v.z +
           sh[8] *(v.x*v.x-v.y*v.y);
}

//--------------------------------------------------------------------------------
// test
//--------------------------------------------------------------------------------


fragmentFn()
{
  float3  lig1 = normalize( float3(1.0, 1.0, 1.0) );
  float3  lig2 = normalize( float3(1.0,-1.0, 0.1) );
  float3  lig3 = normalize( float3(0.0, 0.2,-1.0) );
  float3  lig4 = normalize( float3(0.5, 0.8,-0.5) );

  float3 lco1 = float3(1.0,0.2,0.0);
  float3 lco2 = float3(0.0,1.0,0.0);
  float3 lco3 = float3(0.0,0.0,1.0);
  float3 lco4 = float3(1.0,0.9,0.0);

  float3 sh[9];


	float2 p = worldCoordAspectAdjusted;

     // camera movement	
	float an = 0.2*uni.iTime - 10.0*uni.iMouse.x;
	float3 ro = float3( 2.5*sin(an), 0.0, 2.5*cos(an) );
    float3 ta = float3( 0.0, 0.0, 0.0 );
    // camera matrix
    float3 ww = normalize( ta - ro );
    float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
    float3 vv = normalize( cross(uu,ww));
	// create view ray
	float3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

	float3 col = float3(0.4);

    // Prec-encode the lighting as SH coefficients (you'd usually do this only once)
	sh[0] = float3(0.0);
	sh[1] = float3(0.0);
	sh[2] = float3(0.0);
	sh[3] = float3(0.0);
	sh[4] = float3(0.0);
	sh[5] = float3(0.0);
	sh[6] = float3(0.0);
	sh[7] = float3(0.0);
	sh[8] = float3(0.0);

  if (in.OPTIMIZED) {
    SH_AddLightDirectionalOpt( lco1, lig1, sh );
    SH_AddLightDirectionalOpt( lco2, lig2, sh );
    SH_AddLightDirectionalOpt( lco3, lig3, sh );
    SH_AddLightDirectionalOpt( lco4, lig4, sh );
  } else {
    SH_AddLightDirectionalSlow( lco1, lig1, sh );
    SH_AddLightDirectionalSlow( lco2, lig2, sh );
    SH_AddLightDirectionalSlow( lco3, lig3, sh );
    SH_AddLightDirectionalSlow( lco4, lig4, sh );
  }
	// raytrace-sphere
	float3  ce = ro;
	float b = dot( rd, ce );
	float c = dot( ce, ce ) - 1.0;
	float h = b*b - c;
	if( h>0.0 )
	{
		h = -b - sqrt(h);
		float3 pos = ro + h*rd;
		float3 nor = normalize(pos); 
		
		// compare regular lighting...
		if( sin(TAU*uni.iTime)>0.0 )
        {
			col  = lco1*saturate( dot(nor,lig1));
            col += lco2*saturate( dot(nor,lig2));
            col += lco3*saturate( dot(nor,lig3));
            col += lco4*saturate( dot(nor,lig4));
        }
        // ... with SH lighting
        else			
        {
          if (in.OPTIMIZED) {
            col = SH_EvalulateOpt( nor, sh );
          } else {
            col = SH_EvalulateSlow( nor, sh );
          }
        }
	}
	col *= 0.6;
	return float4( col, 1.0 );
}
