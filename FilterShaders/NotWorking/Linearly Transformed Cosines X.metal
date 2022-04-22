/** 
Author: sergey_reznik
Comparison of Linearly Transformed Cosines to bruteforce path tracing (explicit light sampling)
*/

#define shaderName linearly_transformed_cosines_x

#include "Common.h" 

struct InputBuffer {
  };

initialize() {
  // setTex(0, asset::noise_color_fine);
}

 



 struct Plane 
{
    float3 center;
    float3 s;
    float3 t;
    float2 dim;
    int material;
};
    
struct Ray
{
    float3 origin;
	float3 direction;
};
    
struct Sphere
{
    float3 center;
    float radius;
};
    
struct Material
{
    float3 color;
    float3 emissive;
};
    
struct Light
{
    int plane;
};
    
constant const float2 lightSize = float2(0.468, 0.378);

static bool raySphereIntersection(const Ray r, const Sphere s, thread float& t, thread float3& i, thread float3& n, thread int& m)
{
    float3 dv = s.center - r.origin;
	float b = dot(r.direction, dv);
	float d = b * b - dot(dv, dv) + s.radius * s.radius;
    bool intersects = (d >= 0.0);
    if (intersects)
    {
		t = b - sqrt(d);
        i = r.origin + t * r.direction;
        n = normalize(i - s.center);
        m = 0;
    }
	return intersects;
}

bool rayPlaneIntersection(const Ray r, const Plane p, thread float& t, thread float3& i, thread float3& n, thread int& m)
{
    float3 planeNormal = normalize(cross(p.t, p.s));
	float d = dot(r.direction, planeNormal);
    bool intersects = (d <= 0.0f);
    if (intersects)
    {
        m = p.material;
        n = planeNormal;
    	t = dot(planeNormal, p.center - r.origin) / d;
        i = r.origin + r.direction * t;
        float ds = dot(p.center - i, p.s);
        float dt = dot(p.center - i, p.t);
        intersects = (abs(ds) <= p.dim.x) && (abs(dt) <= p.dim.y);
    }
    return intersects;
}

const float3 cameraPostiion = float3(0.0, 1.0, 3.5);
const float3 cameraTarget = float3(0.0, 1.0, 0.0);
const float3 cameraUp = float3(0.0, 1.0, 0.0);

#define materialsCount 5
Material materials[materialsCount];

#define planesCount 6
Plane planes[planesCount];

#define lightsCount 1
Light lights[lightsCount];

fragmentFn( texture2d<float> lastFrame) {
	float4 fragColor = float4(0.025, 0.05, 0.075, 1.0);
    
    populateMaterials();
    populatePlanes();
    
	float2 p = (2.0 * thisVertex.where.xy - uni.iResolution.xy) / uni.iResolution.y;
    
    float3 w = normalize(cameraTarget - cameraPostiion);
    float3 u = normalize(cross(w, cameraUp));
    float3 v = normalize(cross(u, w));
    
    Ray primaryRay;
    primaryRay.origin = cameraPostiion;
    primaryRay.direction = normalize(p.x * u + p.y * v + 2.5 * w);
    
    float3 intersectionPoint;
    float3 intersectionNormal;
    float minIntersectionDistance = 1000000.0;
    int materialIndex = 0;
    int objectIndex = 0;
    
    bool intersectionOccured = false;
    for (int i = 0; i < planesCount; ++i)
    {
	    float3 p;
    	float3 n;
        int m;
    	float t = 0.0;
        if (rayPlaneIntersection(primaryRay, planes[i], t, p, n, m))
        {
            if (t < minIntersectionDistance)
            {
                objectIndex = i;
                materialIndex = m;
                minIntersectionDistance = t;
                intersectionNormal = n;
                intersectionPoint = p;
                intersectionOccured = true;
            }
        }
    }
    
    if (intersectionOccured == false)
        return;
    
    bool hitLight = false;
    for (int i = 0; i < lightsCount; ++i)
    {
        if (lights[i].plane == objectIndex)
        {
            hitLight = true;
            break;
        }
            
    }
    
    if (hitLight)
    {
        fragColor.xyz = materials[materialIndex].emissive;
        return;
    }
    
	fragColor.xyz = toSRGB(shade(intersectionPoint, intersectionNormal, primaryRay.direction, materialIndex));
  return fragColor;
}

Material makeMaterial(const float3 d, const float3 e)
{
    Material m;
    m.color = d;
    m.emissive = e;
    return m;
}

void populateMaterials()
{
	// float lightArea = lightSize.x * lightSize.y;
    
	materials[0] = makeMaterial(float3(1.0, 1.0, 1.0), float3(0.0, 0.0, 0.0));   
	materials[1] = makeMaterial(float3(0.05, 1.0, 0.05), float3(0.0, 0.0, 0.0));   
	materials[2] = makeMaterial(float3(1.0, 0.05, 0.05), float3(0.0, 0.0, 0.0));   
	materials[3] = makeMaterial(float3(0.0, 0.0, 0.0), float3(15.0, 15.0, 15.0));
}

Plane makePlane(const float3 c, const float3 s, const float3 t, const float2 d, const int m)
{
    Plane p;
    p.center = c;
    p.s = normalize(s);
    p.t = normalize(t);
    p.dim = d / 2.0;
    p.material = m;
    return p;
}

void populatePlanes()
{
    planes[0] = makePlane(float3( 0.0,  0.0,  0.0), float3( 1.0,  0.0, 0.0), float3(0.0, 0.0, 1.0), float2(2.0, 2.0), 0); // floor
    planes[1] = makePlane(float3( 0.0, +2.0,  0.0), float3(-1.0,  0.0, 0.0), float3(0.0, 0.0, 1.0), float2(2.0, 2.0), 0); // ceil
    planes[2] = makePlane(float3( 0.0,  1.0, -1.0), float3(-1.0,  0.0, 0.0), float3(0.0, 1.0, 0.0), float2(2.0, 2.0), 0); // back
    planes[3] = makePlane(float3( 1.0,  1.0,  0.0), float3( 0.0,  1.0, 0.0), float3(0.0, 0.0, 1.0), float2(2.0, 2.0), 1); // right
    planes[4] = makePlane(float3(-1.0,  1.0,  0.0), float3( 0.0, -1.0, 0.0), float3(0.0, 0.0, 1.0), float2(2.0, 2.0), 2); // left
    planes[5] = makePlane(float3( 0.0, +1.998, 0.0), float3(-1.0,  0.0, 0.0), float3(0.0, 0.0, 1.0), lightSize, 3); // light
    
    lights[0].plane = 5;
}

/*
 *
 * shading happens here
 *
 */
float3 toLinear(const float3 srgb)
{
    return pow(srgb, float3(2.2));
}
    
float3 toSRGB(const float3 linear)
{
    return pow(linear, float3(1.0/2.2));
}

float integrateLTC(const float3 v1, const float3 v2)
{
    float cosTheta = dot(v1, v2);
    float theta = acos(cosTheta);    
    return cross(v1, v2).z * ((theta > 0.001) ? theta / sin(theta) : 1.0);
}

float3 mul(const float3x3 m, const float3 p)
{
    return m * p;
}

float evaluateLTC(const float3 position, const float3 normal, const float3 view, const float3 points[4])
{
    float3 t1 = normalize(view - normal * dot(view, normal));
    float3 t2 = cross(normal, t1);

    float3x3 Minv = transpose(float3x3(t1, t2, normal));

    float3 L[4];
    L[0] = normalize(mul(Minv, points[0] - position));
    L[1] = normalize(mul(Minv, points[1] - position));
    L[2] = normalize(mul(Minv, points[2] - position));
    L[3] = normalize(mul(Minv, points[3] - position));

    float sum = 0.0;
    sum += integrateLTC(L[0], L[1]);
    sum += integrateLTC(L[1], L[2]);
    sum += integrateLTC(L[2], L[3]);
	sum += integrateLTC(L[3], L[0]);
    return max(0.0, sum); 
}

float3 sampleLight(const float3 p[4], const float4 rnd)
{
    float3 pt = mix(p[0], p[1], rnd.x);
    float3 pb = mix(p[3], p[2], rnd.x);
    return mix(pt, pb, rnd.y);
}

float3 shade(const float3 position, const float3 normal, const float3 view, const int materialId)
{
    float4 rnd = texture[0].sample(iChannel0, 100.0 * (normal.xy + position.y * view.yx - position.xz) + uni.iTime);
    
	float lightArea = lightSize.x * lightSize.y;
    Plane lightPlane = planes[lights[0].plane];
    Material lightMaterial = materials[lightPlane.material];
    float3 materialColor = materials[materialId].color;
    float3 lightColor = lightMaterial.emissive;
    float3 lightNormal = normalize(cross(lightPlane.s, lightPlane.t));
    float3 lightPoints[4];
    lightPoints[0] = lightPlane.center + lightPlane.s * lightPlane.dim.x - lightPlane.t * lightPlane.dim.y;
    lightPoints[1] = lightPlane.center + lightPlane.s * lightPlane.dim.x + lightPlane.t * lightPlane.dim.y;
    lightPoints[2] = lightPlane.center - lightPlane.s * lightPlane.dim.x + lightPlane.t * lightPlane.dim.y;
    lightPoints[3] = lightPlane.center - lightPlane.s * lightPlane.dim.x - lightPlane.t * lightPlane.dim.y;
    
 //   float3 l = normalize(lightPlane.center - position);
//    float lambert = dot(normal, l) / PI;
    
    float ltc = evaluateLTC(position, normal, view, lightPoints) / (2.0 * PI);
    
    float bruteforced = 0.0;
    const int samples = 500;
    for (int i = 0; i < samples; ++i)
    {
        float3 pl = sampleLight(lightPoints, rnd) - position;
		float DdotL = dot(pl, lightNormal);
        float LdotN = dot(pl, normal);
        if ((LdotN > 0.0) && (DdotL > 0.0))
        {
    	    float distanceSquared = dot(pl, pl);
            float distanceToPoint = sqrt(distanceSquared);
            float pdf = distanceSquared / (DdotL / distanceToPoint * lightArea);
            float bsdf = 1.0 / PI;
        	bruteforced += bsdf / pdf * (LdotN / distanceToPoint);
        }
    	rnd = texture[0].sample(iChannel0, rnd.xz + 23.0 * rnd.yx);
    }
    bruteforced /= float(samples);
    
    return lightColor * materialColor * ltc; // abs(ltc - bruteforced);
}

