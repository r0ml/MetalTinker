
#define shaderName Raytracing_textured_triangles

#include "Common.h"

constant const float EPSILON = 0.0000001;
constant const float4 BG_COLOR = float4(0.0, 0.0, 0.0, 1.0);

struct Intersection
{
    float3 intersection;
    float t;
    float2 uv;
    float4 color;
    float3 normal;
    float3 r;
};

struct Triangle
{
	float3 vertex0;
    float3 vertex1;
    float3 vertex2;
	float2 uv0;	
	float2 uv1;	
	float2 uv2;
    int material;
};

#define UVA float2(0.0, 0.0)
#define UVB float2(0.0, 1.0)
#define UVC float2(1.0, 1.0)
#define UVD float2(1.0, 0.0)


#define TRIANGLE_COUNT 4


// https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm

static bool RayIntersectsTriangle(const float3 rayOrigin,
                           const float3 rayVector,
                           const Triangle tri,
                           thread Intersection& ip)
{    
	float3 vertex0 = tri.vertex0;
	float3 vertex1 = tri.vertex1;
	float3 vertex2 = tri.vertex2;

    float3 edge1, edge2, h, s, q;
    
    float a,f,u,v;
    edge1 = vertex1 - vertex0;
    edge2 = vertex2 - vertex0;
    h = cross(rayVector, edge2);
    a = dot(edge1, h);
    if (a > -EPSILON && a < EPSILON)
        return false;
    
    f = 1.0 / a;
    s = rayOrigin - vertex0;
    u = f * dot(s,h);
    if (u < 0.0 || u > 1.0)
        return false;
    
    q = cross(s, edge1);
    v = f * dot(rayVector, q);
    if (v < 0.0 || u + v > 1.0)
        return false;
    
    // At this stage we can compute t to find out where the intersection point is on the line.
    float t = f * dot(edge2, q);
    if (t > EPSILON) // ray intersection
    {   
        ip.t = t;
        ip.normal = normalize(cross(edge1, edge2));
        ip.intersection = rayOrigin + rayVector * t;
        ip.uv = float2(u, v);
        return true;
    }
    else // This means that there is a line intersection but not a ray intersection.
        return false;
}

// https://www.shadertoy.com/view/XsB3Rm

constant const float DEG_TO_RAD = PI / 180.0;

// get ray direction
static float3 ray_dir( float fov, float2 size, float2 pos ) {
	float2 xy = pos - size * 0.5;

	float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );	
	float z = size.y * 0.5 * cot_half_fov;
	
	return normalize( float3( xy, -z ) );
}

// camera rotation : pitch, yaw
static float3x3 rotationXY( float2 angle ) {
	float2 c = cos( angle );
	float2 s = sin( angle );
	
	return float3x3(
		c.y      ,  0.0, -s.y,
		s.y * s.x,  c.x,  c.y * s.x,
		s.y * c.x, -s.x,  c.y * c.x
	);
}

constant const Triangle triangleList[4] = {
  Triangle { float3(-0.5, 0.0, 0.0), float3(-0.5, 1.0, 0.0), float3( 0.5, 1.0, 0.0), UVA, UVB, UVC, 0 } ,
  Triangle { float3(-0.5, 0.0, 0.0), float3( 0.5, 1.0, 0.0), float3( 0.5, 0.0, 0.0), UVA, UVC, UVD, 0 } ,

  Triangle { float3(-1.0, 0.0, -1.0), float3(-1.0, 0.0, 1.0), float3( 1.0, 0.0,  1.0), UVA, UVB, UVC, 1 } ,
  Triangle { float3(-1.0, 0.0, -1.0), float3( 1.0, 0.0, 1.0), float3( 1.0, 0.0, -1.0), UVA, UVC, UVD, 1 }
};


static float4 getColor(Triangle t, Intersection ip, texture2d<float> tex0, texture2d<float> vid0)
{  
    float4 color;
    
    float2 uv = ip.uv.x * t.uv1 + ip.uv.y * t.uv2 + (1.0 - ip.uv.x - ip.uv.y) * t.uv0;
    if (t.material == 0) {
        color = vid0.sample(iChannel0, uv);
    } else {
        color = tex0.sample(iChannel0, uv);
    }
    ip.color = color;
    return color;
}

static bool rayTrace(const float3 ro, const float3 rd, thread float4& color, thread Intersection& hitIp, thread Triangle& hitTri, texture2d<float> tex0, texture2d<float> vid0)
{
    color = BG_COLOR;
    
    float t = 10000.0;
    bool hit = false;
    
    for (int i = 0; i < TRIANGLE_COUNT; i++)
    {
        Intersection ip;
        Triangle tri = triangleList[i];
	    if (RayIntersectsTriangle(ro, rd, tri, ip))
        {
            if (ip.t < t) {
                ip.r = normalize(reflect(ip.intersection - ro, ip.normal));
                color = getColor(tri, ip, tex0, vid0);
                t = ip.t;
                hitIp = ip;
                hitTri = tri;
                hit = true;
            }
        }
    }        
    return hit;
}

/*static void initScene()
{
  triangleList[0] = Triangle { float3(-0.5, 0.0, 0.0), float3(-0.5, 1.0, 0.0), float3( 0.5, 1.0, 0.0), UVA, UVB, UVC, 0 } ;
  triangleList[1] = Triangle { float3(-0.5, 0.0, 0.0), float3( 0.5, 1.0, 0.0), float3( 0.5, 0.0, 0.0), UVA, UVC, UVD, 0 } ;
    
  triangleList[2] = Triangle { float3(-1.0, 0.0, -1.0), float3(-1.0, 0.0, 1.0), float3( 1.0, 0.0,  1.0), UVA, UVB, UVC, 1 } ;
  triangleList[3] = Triangle { float3(-1.0, 0.0, -1.0), float3( 1.0, 0.0, 1.0), float3( 1.0, 0.0, -1.0), UVA, UVC, UVD, 1 } ;
}*/

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {


  float3 dir = ray_dir( 45.0, uni.iResolution.xy, thisVertex.where.xy );
    float3 eye = float3( 0.0, 0.3, 2.0 );
  float3x3 rot = rotationXY( float2( 0.0 ,uni.iTime ) );
	float3 rd = rot * dir;
    float3 ro = rot * eye;

    float4 color = BG_COLOR;
    Intersection ip;
    Triangle tri;
 
    if (rayTrace(ro, rd, color, ip, tri, tex0, tex1))
    {
    	if (tri.material == 1)
    	{            
            float4 refcolor = BG_COLOR;
            rayTrace(ip.intersection + ip.r * 0.000001, ip.r, refcolor, ip, tri, tex0, tex1);
            
        	color = 0.5 * color + 0.5 * refcolor;
    	}
    }

    return color;
}

