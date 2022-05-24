/** 
Author: Dalton
Raymarched torus w/ cel shading. Plan on adding AA later.
*/

#define shaderName toon_shaded_torus

#include "Common.h" 

struct InputBuffer {
};
initialize() {}

 


constant const float EPSILON = 0.0001;
constant const int MAX_STEPS = 500;
constant const float MIN_DIST = 0.0;
constant const float MAX_DIST = 25.0;

constant const float AMBIENT = 0.1;
constant const float EDGE_THICKNESS = 0.015;
constant const float SHADES = 4.0;

float TorusSDF(float3 samplePoint, float2 dimensions)
{
	return length( float2(length(samplePoint.xz)-dimensions.x,samplePoint.y) )-dimensions.y;
}

float SceneSDF(float3 samplePoint)
{
    return TorusSDF(samplePoint, float2(1.3, 0.45));
}

float March(float3 origin, float3 direction, float start, float stop, thread float& edgeLength)
{
    float depth = start;
    
    for	(int i = 0; i < MAX_STEPS; i++)
    {
        float dist = SceneSDF(origin + (depth * direction)); // Grab min step
        edgeLength = min(dist, edgeLength);
        
        if (dist < EPSILON) // Hit
            return depth;
        
        if (dist > edgeLength && edgeLength <= EDGE_THICKNESS ) // Edge hit
            return 0.0;
        
        depth += dist; // Step
        
        if (depth >= stop) // Reached max
            break;
    }
    
    return stop;
}

float3 RayDirection(float fov, float2 size, float2 winCoord)
{
    float2 xy = winCoord - (size / 2.0);
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(float3(xy, -z));
}

float3 EstimateNormal(float3 point)
{
    return normalize(float3(SceneSDF(float3(point.x + EPSILON, point.y, point.z)) - SceneSDF(float3(point.x - EPSILON, point.y, point.z)),
                          SceneSDF(float3(point.x, point.y + EPSILON, point.z)) - SceneSDF(float3(point.x, point.y - EPSILON, point.z)),
                          SceneSDF(float3(point.x, point.y, point.z + EPSILON)) - SceneSDF(float3(point.x, point.y, point.z - EPSILON))));
}

float4x4 LookAt(float3 camera, float3 target, float3 up)
{
    float3 f = normalize(target - camera);
    float3 s = cross(f, up);
    float3 u = cross(s, f);
    
    return float4x4(float4(s, 0.0),
        		float4(u, 0.0),
        		float4(-f, 0.0),
        		float4(0.0, 0.0, 0.0, 1));
}

float3 ComputeLighting(float3 point, float3 lightDir, float3 lightColor)
{
    float3 color = float3(AMBIENT);
    float intensity = dot(EstimateNormal(point), normalize(lightDir));
    intensity = ceil(intensity * SHADES) / SHADES;
    intensity = max(intensity, AMBIENT);
    color = lightColor * intensity;
    return color;
}

fragmentFn() {
    float3 viewDir = RayDirection(45.0, uni.iResolution.xy, thisVertex.where.xy);
    float3 origin = float3(sin(uni.iTime) * 9.0, (sin(uni.iTime * 2.0) * 4.0) + 6.0, cos(uni.iTime) * 9.0);
    float4x4 viewTransform = LookAt(origin, float3(0.0), float3(0.0, 1.0, 0.0));
    viewDir = (viewTransform * float4(viewDir, 0.0)).xyz;
    
    float edgeLength = MAX_DIST;
    float dist = March(origin, viewDir, MIN_DIST, MAX_DIST, edgeLength);
    
    if (dist > MAX_DIST - EPSILON) // No hit
    {
        return float4(0.6);
    }
    
    if (dist < EPSILON) // Edge hit
    {
        return float4(0.0);
    }
    
    float3 hitPoint = origin + (dist * viewDir);
    float3 lightDir = float3(sin(uni.iTime * 2.0) * 6.0, 4.0, sin(uni.iTime * 1.25) * 5.0);
    float3 color = float3(1.0, 0.5, 0.1);
    
    color = ComputeLighting(hitPoint, lightDir, color);
    
    return float4(color, 1.0);
}

