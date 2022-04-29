
#define shaderName Cornell_box_5367

#include "Common.h"

#define MAXRAYS 10
#define MAXBOUNCES 7
#define INF 100000.0
#define BRIGHTNESS 1.0

#define R(p,a) p=cos(a)*p+sin(a)*float2(-p.y,p.x);

class shaderName  {
public:
  struct Ray {
    float3 origin;
    float3 dir;
  };

  // A camera. Has a position and a direction.
  struct Camera {
    float3 pos;
    Ray ray;
  };

  struct Sphere {
    float3 pos;
    float radius;
  };

  struct Box {
    float3 pos;
    float3 size;
  };

  struct HitTest {
    bool hit;
    float dist;
    float3 normal;
    float4 col;
    float ref;
  };

  // float t;
  // float divergence;

  bool hte(const HitTest a, const HitTest b) {
    return a.hit == b.hit && a.dist == b.dist && all(a.normal == b.normal) && all(a.col == b.col) && a.ref == b.ref;
  }

#define NOHIT HitTest { false, INF, float3(0), float4(0), 0.0 } 

  HitTest minT(const HitTest a, const HitTest b) {
    if (a.dist < b.dist) { return a; } else { return b; }
  }

  HitTest minT(const HitTest a, const HitTest b, const HitTest c) {
    return minT(a, minT(b, c));
  }

  HitTest minT(const HitTest a, const HitTest b, const HitTest c, const HitTest d) {
    return minT(a, minT(b, c, d));
  }

  HitTest minT(const HitTest a, const HitTest b, const HitTest c, const HitTest d, const HitTest e) {
    return minT(minT(a,b), minT(c,d,e));
  }

  HitTest intersectFloor(const Ray r) {
    if (r.dir.y >= 0.0) { return NOHIT; }
    return HitTest { true, r.origin.y / -r.dir.y, float3(0,1,0), float4(0), 0.0 } ;
  }

  HitTest intersectBox(const Ray r, Box b) {
    // box, 0 on y, +/-10 on x, +20 on y
    // float3 p = float3(0);
    // float3 s = float3(30);
    b.size *= 0.5;
    float3 ba = b.pos-b.size, bb = b.pos+b.size;
    
    HitTest h = NOHIT;
    float d = INF;
    
    //r.origin -= p;
    
    float3 dA = (r.origin - ba) / -r.dir;
    float3 dB = (r.origin - bb) / -r.dir;
    
    dA.x = dA.x <= 0.0 ? INF : dA.x;
    dA.y = dA.y <= 0.0 ? INF : dA.y;
    dA.z = dA.z <= 0.0 ? INF : dA.z;
    dB.x = dB.x <= 0.0 ? INF : dB.x;
    dB.y = dB.y <= 0.0 ? INF : dB.y;
    dB.z = dB.z <= 0.0 ? INF : dB.z;
    
    float d1 = min(dA.x, min(dA.y, dA.z));
    float d2 = min(dB.x, min(dB.y, dB.z));
    
    d = min(d1, d2);
    
    float3 endPoint = r.origin + r.dir * d;
    endPoint -= b.pos;
    //endPoint = abs(endPoint);
    
    
    if (d != INF) {
      h.hit = true;
      h.dist = d;
      h.ref = 0.0;

      if (abs(abs(endPoint.x) - bb.x) < 0.01) {
        bool l = endPoint.x < 0.0;
        h.normal = float3(l ? 1 : -1,0,0);
        h.col = l ? float4(1,0.5,0.5,1) : float4(0.5,0.5,1,1);
        return h;
      }
      if (abs(abs(endPoint.z) - bb.z) < 0.01) {
        h.normal = float3(0,0,-sign(endPoint.z));
        h.col = float4(1);
        // h.ref = 0.5;
        return h;
      }

      // floor
      h.normal = float3(0,-sign(endPoint.y),0);
      h.col = float4(1);
      return h;
    }
    return h;
  }

  HitTest intersectSphere(const Ray r, const Sphere s, const float time) {
    float3 o = r.origin - s.pos;
    float v = dot(o, r.dir);
    if(v > 0.) return NOHIT;
    
    float disc = (s.radius * s.radius) - (dot(o, o) - (v * v));

    if(disc < 0.) return NOHIT;

    float dist = length(o) - (sqrt(disc));
    return HitTest { true, dist, normalize((r.origin + r.dir * dist) - s.pos), float4(0), sin(time * 0.25)*.5+.5 } ;
  }

  float3 trand(const float2 n, texture2d<float> rendin) {
    return rendin.sample(iChannel0, n).rgb;
  }

  float4 traceScene(const Camera cam, float2 seed, const float time, const float divergence) {
    //    float3 startPos = cam.pos;
    
    float4 result = float4(0);
    
    float eps = 0.0;
    
    for (int i=0; i<MAXRAYS; i++) {
      Ray r = cam.ray;

      r.dir.x += (rand(seed)*2.-1.) * divergence;
      r.dir.y += (rand(seed.yx)*2.-1.) * divergence;
      r.dir.z += (rand(seed.xx)*2.-1.) * divergence;
      r.dir = normalize(r.dir);
      float4 impact = float4(BRIGHTNESS);
      seed++;

      for (int j=0; j<MAXBOUNCES; j++) {
        HitTest t0 = intersectBox(r, Box { float3(0,10,0), float3(30,20,25) } );
        HitTest t1 = intersectSphere(r, Sphere { float3(-1,2,0), 2.0  } , time) ;
        t1.col = float4(1);
        HitTest t2 = intersectSphere(r, Sphere { float3(4,5,4), 5.0 } , time) ;
        t2.col = float4(1,1,0,1);
        HitTest t3 = intersectSphere(r, Sphere { float3(-10.,6,0.), 1.0 } , time);
        HitTest t4 = intersectSphere(r, Sphere { float3(0,20,0), 10.0 }, time );

        HitTest test = minT(t0, t1, t2, t4);//, t4);

        if (( hte(test,t3)  ) && test.hit) {
          result += float4(1) * impact;
          break;
        } else if ((  hte(test,t4) ) && test.hit) {
          result += float4(1) * impact;
          break;
        }
        if (test.hit) {
          r.origin += r.dir * test.dist;
          r.origin += test.normal * 0.01;
          float3 random = float3(
                                 rand(r.origin.xy+seed),
                                 rand(r.origin.yz+seed),
                                 rand(r.origin.zx+seed)
                                 )*2. - 1.;
          //random = normalize(random);
          eps += divergence * test.dist*0.1;
          r.dir = normalize(mix(
                                test.normal + random,
                                reflect(r.dir, test.normal),
                                test.ref
                                ));
          r.origin += r.dir * eps;
          //r.dir = test.normal;
          impact *= test.col;
        } else {
          break;
        }
      }
    }
    return result / float(MAXRAYS);
  }

  // Sets up a camera at a position, pointing at a target.
  // uv = fragment position (-1..1) and fov is >0 (<1 is telephoto, 1 is standard, 2 is fisheye-like)
  Camera setupCam( float3 pos, const float3 target, const float fov, float2 uv, const float2 reso, const float2 mousex, thread float& divergence) {
    // cam setup
    float2 mouse = mousex;
    mouse = mouse * 2.;// - 1.;
    R(pos.xz, mouse.x);
    // Create camera at pos
    Camera cam;
    cam.pos = pos;
    
    // A ray too
    Ray ray;
    ray.origin = pos;
    
    // FOV is a simple affair...
    uv *= fov;
    
    // Now we determine hte ray direction
    float3 cw = normalize (target - pos );
    float3 cp = float3 (0.0, 1.0, 0.0);
    float3 cu = normalize ( cross(cw,cp) );
    float3 cv = normalize ( cross (cu,cw) );
    
    ray.dir = normalize ( uv.x*cu + uv.y*cv + 0.5 *cw);
    
    // Add the ray to the camera and our work here is done.
    cam.ray = ray;
    
    // Ray divergence
    divergence = fov / reso.x;
    divergence = divergence + length(uv) * 0.02;
    return cam;
  }

};


fragmentFn(texture2d<float> lastFrame) {
  shaderName shad;

  float divergence;

  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  uv = uv * 2. - 1.;
  uv.y /= uni.iResolution.x/uni.iResolution.y;
  shaderName::Camera cam = shad.setupCam(float3(0,3,-8), float3(0,5,0), 1.0, uv, uni.iResolution, uni.iMouse, divergence);
  //Camera(float3(0, 5, -10), normalize(float3(uv, 1.0)));

  float4 c = shad.traceScene(cam, uv + uni.iTime, uni.iTime, divergence);
  float4 l = lastFrame.sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy);
  return mix(c, l, uni.wasMouseButtons ? 0.0 : 0.98);
}
