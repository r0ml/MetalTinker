/** 
Author: lara
Part of another shader I am working on.
Cubic roots are so sloooow..
*/

// Change resolution in Buf A

#define shaderName floating_bands

#include "Common.h" 

struct InputBuffer {
  };

initialize() {
  // setTex(0, asset::noise_color_fine);
}

 

// #define inside(a) (thisVertex.where.x == a.x+0.5 && thisVertex.where.y == a.y+0.5)
// #define load(a,b) texture(b,(a+0.5)/uni.iResolution.xy)

fragmentFn(texture2d<float> tex) {
   	// float2 uv = thisVertex.where.xy / uni.iResolution.xy;
    float res = renderInput[0].sample(iChannel0, (float2(0,0) + 0.5)/uni.iResolution).x;
    
    fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy/uni.iResolution.xy*res);
}

 // ============================================== buffers ============================= 

constant int _num_objects = 2;

tClass(a)

 #define RES (1./2.)
#define inside(a) (thisVertex.where.x == a.x+0.5 && thisVertex.where.y == a.y+0.5)
#define load(a,b) textureLod(b,(a+0.5)/uni.iResolution.xy,0.)

#define SHADOW
#define AMBIENT_OCCLUSION

#define T uni.iTime

#define P 0.001  // Precision
#define D 10.    // Max distance
#define S 256    // Marching steps
#define R 1.     // Marching substeps
#define K 32.    // Shadow softness
#define A 4.     // AO steps

/* ======================== */
/* === Marching Globals === */
/* ======================== */

struct Hit {
	float3 p;
	float t;
	float d;
	float s;
};

struct Ray {
	float3 o;
	float3 d;
} _ray;

struct Cam {
	float3 p;
	float3 t;
    float3 u;
    float f;
} _cam;


float _d, _obj[_num_objects];

int _ignore = -1;

bool _ambientOccMarch = false;
bool _shadowMarch = false;
bool _normalMarch = false;

/* ================= */
/* === Utilities === */
/* ================= */


float3 fbm(float2 p)
{
    float3 f = float3(0);
	
    // just noticed that this is the wrong way around
    // but it actually doesn't look too bad
    f += textureLod(texture[0], iChannel0,p/08.,0.).rgb*1.;
    f += textureLod(texture[0], iChannel0,p/04.,0.).rgb*2.;
    f += textureLod(texture[0], iChannel0,p/02.,0.).rgb*4.;
    f += textureLod(texture[0], iChannel0,p/01.,0.).rgb*8.;
    
    return f/(1.+2.+4.+8.);
}

// https://en.wikipedia.org/wiki/Cubic_function#Cardano.27s_method
float3 cubicRoot(float a, float b, float c, float d)
{
	float p = (9.*a*c-3.*b*b)/(9.*a*a);
	float q = (2.*b*b*b-9.*a*b*c+27.*a*a*d)/(27.*a*a*a);
	float p3 = p*p*p;
	float e = q*q+4.*p3/27.;

	if (e > 0.0)
	{
		e = sqrt(e);
        
		float u = (-q+e)/2.;
		float v = (-q-e)/2.;
        
		u = (u>=0.) ? pow(u,1./3.) : -pow(-u,1./3.);
		v = (v>=0.) ? pow(v,1./3.) : -pow(-v,1./3.);
        
		return float3(u+v-b/(3.*a),1.0,1.0);
	}

	float u = 2.*sqrt(-p/3.);
    float v = acos(-sqrt(-27./p3)*q/2.)/3.;
    
	return float3(
        u*cos(v),
        u*cos(v+2.*PI/3.),
        u*cos(v+4.*PI/3.))-b/(3.*a
	);
}

/* ===================== */
/* === SDF Functions === */
/* ===================== */

float udBox(float3 p, float3 s, float r)
{
    return length(max(abs(p)-s+r,0.))-r;
}

// q1 = a + ac*t
// q2 = c + cb*t
// q3 = a + 2(ac)*t + (a+b-2c)*t²
// (p-q3)(q2-q1)=0
float sdBand(float3 p, float3 a, float3 b, float3 c, float3 n, float r)
{ 
	float3 ac = c-a;
	float3 ap = p-a;
	float3 abc = -2.*c+a+b;

	float3 t = clamp(cubicRoot(
		-dot(abc,abc),
		-3.*dot(abc,ac),
		-2.*dot(ac,ac)+dot(ap,abc),
		dot(ap,ac)
	),0.,1.);

	float3 q1 = (2.*ac+abc*t.x)*t.x;
	float3 q2 = (2.*ac+abc*t.y)*t.y;
	float3 q3 = (2.*ac+abc*t.z)*t.z;
	
	return min(min(udBox(ap-q1,(1.-n)*r,0.),udBox(ap-q2,(1.-n)*r,0.)),udBox(ap-q3,(1.-n)*r,0.));
}

/* ============ */
/* === Scene=== */
/* ============ */

float scene(float3 p)
{
	 float d = 1e10;
    
    // Floor
    _obj[0] = p.y+1.;
    
    for(int i = 0; i < 10; i++)
    {
        float3 p1 = (fbm(float2(i  ,T)/textureSize(texture[0])).rgb-.5)*2.;
        float3 p2 = (fbm(float2(i+1,T)/textureSize(texture[0])).rgb-.5)*2.;
        float3 p3 = (fbm(float2(i+2,T)/textureSize(texture[0])).rgb-.5)*2.;
    	d = min(d,sdBand(p,p1,p2,p3,float3(0,1,0),0.01));
    }
    
    // Swirls
    _obj[1] = d; d = 1e10;

	for(int i = 0; i < _num_objects; i++)
	{
		//if (_ignore == i) continue;
		d = min(d,_obj[i]);
	}

	_d = d;

	return d;
}

/* ================ */
/* === Marching === */
/* ================ */

Ray lookAt(Cam c, float2 uv)
{
	float3 d = normalize(c.t - c.p);
	float3 r = normalize(cross(d,c.u));
	float3 u = cross(r,d);

  return Ray { c.p*c.f, normalize(uv.x*r + uv.y*u + d*c.f) } ;
}

Hit march(Ray r)
{
	float t = 0., d, s = 0;
	float3 p;
	
	for(int i = 0; i < S; i++)
	{
		d = scene(p = r.o + r.d*t);

		if (d < P || t > D)
		{
			s = float(i);
			break;
		}

		t += d/R;
	}

  return Hit { p, t, d, s } ;
}

float3 getNormal(float3 p)
{
    _normalMarch = true;
    
	float2 e = float2(P,0.);

	return normalize(float3(
		scene(p+e.xyy)-scene(p-e.xyy),
		scene(p+e.yxy)-scene(p-e.yxy),
		scene(p+e.yyx)-scene(p-e.yyx)
	));
}

/* =============== */
/* === Shading === */
/* =============== */

float getShadow(float3 light, float3 origin)
{
	_shadowMarch = true;

	float3 d = normalize(light - origin);
	float t = 0.;
	float maxt = length(light - origin)-.1;
	float s = 1.0;
    
    const int n = S/4;

	for(int i = 0; i < n; i++)
	{
		// float d = scene(origin + d * t);
		if (t > maxt || t > D) { break; }
		t += d.x;
    s = min(s,d.x/t*K);
	}

	return s;
}

float getAmbientOcclusion(Hit h) 
{
    _ambientOccMarch = true;
    
  float t = 0.; // , a = 0.;
    
	for(float i = 0.; i < A; i++)
    {
        float d = scene(h.p-_ray.d*i/A*.2);
        t += d;
    }

	return saturate(t/A*20.);
}

float3 getColor(Hit h)
{
    float3 fog = float3(0);
	if (h.d > P) { return fog; }

	float3 col = float3(0);
	float3 n = getNormal(h.p);
    float3 light = float3(0,10,0);

	// float diff = max(dot(n, normalize(light-h.p)),.1);
	// float spec = pow(max(dot(reflect(normalize(h.p-light),n),normalize(_cam.p-h.p)),0.),100.);
	float dist = saturate(length(h.p)/D*1.5);
    
    if (_d == _obj[0])
    {
        col = float3(.5) * max(n.y,.5);
    }
    else if (_d == _obj[1])
    {
		col = float3(2,1.5,0) * max(n.y,.5);
    }
    
    #ifdef SHADOW
    col *= max(getShadow(light,h.p),.5);
    #endif
    
    #ifdef AMBIENT_OCCLUSION
    col *= getAmbientOcclusion(h);
    #endif

    return mix(col,fog,dist);
}

/* ============ */
/* === Main === */
/* ============ */

fragmentFn(texture2d<float> tex) {
    if (inside(float2(0,0))) { fragColor.x = RES; return; }
    
  _cam = Cam { float3(0,.5,-1), float3(0),float3(0,1,0),1. } ;
    _ray = lookAt(_cam,(2.*thisVertex.where.xy/RES-uni.iResolution.xy)/uni.iResolution.xx);
    
    float f = 1.-length((2.0*thisVertex.where.xy/RES-uni.iResolution.xy)/uni.iResolution.xy)*0.5;
	fragColor = float4(getColor(march(_ray))*f,1);
}

tRun
