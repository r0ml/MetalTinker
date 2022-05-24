/** 
Author: ShnitzelKiller
testing a modified version of iq's approximate soft shadows, which extends the penumbra inwards as well as outwards.The space between the pillars would not cast a sliver of light on the floor otherwise.
*/

#define shaderName a_Cylinder_3

#include "Common.h" 

struct InputBuffer {
};
initialize() {}

 


#define fdist 0.5
#define maxdist 100.
#define iters 40
#define shadowiters 70
#define threshold 0.025
#define eps 0.01
#define shadoweps 0.1
#define lightdir normalize(float3(1., 1., 0.))

static float cylindersdf(float3 pos, float3 c, float r, float h) {
    pos -= c;
    return max(length(pos.xz)-r, max(-pos.y, pos.y - h));
}

static float sdf(float3 pos) {
    float h1 = cylindersdf(pos, float3(0., 0., 0.55), 0.5, 5.);
    float h2 = cylindersdf(pos, float3(0., 0., -0.55), 0.5, 5.);
    return min(max(length(pos.xz)-7., pos.y), min(h1, h2));
}

static float3 getnormal(float3 pos) {
    float xp = sdf(pos + float3(eps, 0., 0.));
    float xm = sdf(pos - float3(eps, 0., 0.));
    float ddx = xp - xm;
    float yp = sdf(pos + float3(0., eps, 0.));
    float ym = sdf(pos - float3(0., eps, 0.));
    float ddy = yp - ym;
    float zp = sdf(pos + float3(0., 0., eps));
    float zm = sdf(pos - float3(0., 0., eps));
    float ddz = zp - zm;
    return normalize(float3(ddx, ddy, ddz));
}

static float2 raytrace(float3 eye, float3 rd) {
    int i;
    float t = 0.;
    float dist = sdf(eye);
    for (i=0; i<iters; i++) {
        t += dist;
        dist = sdf(eye + t*rd);
        if (abs(dist) < threshold) {
            return float2(t, 1.);
        } else if (dist > maxdist) {
            break;
        }
    }
    return float2(t, 0.);
}

//a version of soft shadow raytracing that uses the distance to surfaces from both inside and outside
static float shadowtrace(float3 ro, float3 rd, float sharpness) {
    int i;
    float t = shadoweps;
    float dist = sdf(ro+t*rd);
    float fac = 1.0;
    for (i=0; i<shadowiters; i++) {
        t += clamp(dist/10., 0.1, 0.2);
        dist = sdf(ro + t*rd);
        fac = min(fac, dist * sharpness / t);
    }
    return fac > 0. ? mix(0.5, 1., fac) : mix(0.5, 0., -fac);
}

fragmentFn() {
    float alt = clamp(uni.iMouse.y,0.15, 1.) * PI/2.;
    float azi = (uni.iMouse.x-0.35) * TAU;
    float cphi = cos(alt);
    float3 eye = 10. * float3(sin(azi)*cphi, sin(alt), cos(azi)*cphi);
    eye.y += 2.;
    float sharpness = 4.*sin(uni.iTime) + 5.;
    float3 w = -normalize(eye);
    float3 u = normalize(cross(w, float3(0., 1., 0.)));
    float3 v = cross(u, w);
    float3 rd = normalize(fdist*w + (thisVertex.where.x/uni.iResolution.x-0.5)*u + (thisVertex.where.y-0.5*uni.iResolution.y)/uni.iResolution.x*v);
    
	float2 d = raytrace(eye, rd);
    if (d.y < 0.5) {
        return float4(0., 0., 0., 1.);
    } else {
        float3 n = getnormal(eye + rd * d.x);
        float shade = max(0., dot(n, lightdir));
        float fac = shadowtrace(eye+rd*d.x, lightdir, sharpness);
        fac = min(fac, shade);
        return float4((n+1.)/2.*max(fac, 0.15), 1.);
    }
}

