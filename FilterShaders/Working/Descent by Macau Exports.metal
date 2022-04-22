
#define shaderName Descent_by_Macau_Exports

#include "Common.h"

class shaderName  {
public:

  float buildings, buildings2, sea, seabrite, bust, intro, end, struckfinal, startmove, surface, spaceboost;
  float zofs;

  float2 pR(const float2 p, float a) {
    return cos(a)*p + sin(a)*float2(p.y, -p.x);
  }

  float smootherstep(float a, float b, float r) {
    r = saturate(r);
    return mix(a, b, r * r * r * (r * (6.0 * r - 15.0) + 10.0));
  }


  float sa, sb, sc, sd;
  float2 su;

  float snoise(const float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    // Four corners in 2D of a tile
    sa = rand(i);
    sb = rand(i + float2(1.0, 0.0));
    sc = rand(i + float2(0.0, 1.0));
    sd = rand(i + float2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    su = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 corners
    return mix(sa, sb, su.x) +
    (sc - sa)* su.y * (1.0 - su.x) +
    (sd - sb) * su.x * su.y;
  }

  float3 cc;

  // Repeat in three dimensions
  /*float3 pMod3(thread float3& p, float3 size) {
   cc = floor((p + size*0.5)/size);
   p = mod(p + size*0.5, size) - size*0.5;
   return cc;
   }*/

  float3 op, small;
  float side, thick, bt, ofs;

  float3 space(float3 p, float t) {
    op=p;
    p.y = abs(p.y - buildings*10.0);
    p.z += zofs;
    side = abs(sin(p.x*0.2)*sin(p.z*0.2));

    thick = -0.00;
    bt = 0.82*buildings;
    bt += ( 1.0*snoise(p.xz*(0.4))) ;
    bt += (p.y*0.02 - 0.2*snoise(p.yy*0.2+p.z));
    bt += cos(p.x*0.5);
    bt += 0.5*snoise(p.yz*10.0);
    
    thick += buildings*bt;
    
    //thick += -0.2 + 0.4*sea*snoise(p.yy*0.2);

    thick += 0.6*sin(p.y*0.3) *seabrite*abs(sin(t*0.06-1.0)); // TODO fix sync
    thick += (1.0-buildings) * (snoise(p.xz*(2.0) + float2(t*0.0,t*0.1))+snoise(p.yy*3.0));
    thick += 0.3*sea - 0.35*seabrite;
    thick += 0.3*sign(-op.y+4.9)*struckfinal;
    //thick += sin(p.y/(1.0+p.y));
    
    //p.x += (sin(p.z+t*.5))*.5 * sea;
    //p.y += (sin(p.x+t*.4))*.5 * sea;
    p.xy += 0.5*sin(p.zx*2.0+float2(t*.5, t*.2))*sea;
    
    ofs = pow(thick*1.0 + sin(p.x+t*0.1)*0.1, 2.0);

    /*float3 pMod3(thread float3& p, float3 size) {
     cc = floor((p + size*0.5)/size);
     p = mod(p + size*0.5, size) - size*0.5;
     return cc;
     }*/
    //cc = floor((p + size*0.5)/size);
    float3 size = float3(0.4);
    p = mod(p + size*0.5, size) - size*0.5;
    //pMod3(p, float3(0.4));

    float3 red = float3(1.0, 0.7, 0.1)*(0.2+spaceboost*0.8);
    small = mix(
                mix(red, float3(0.3, 0.4, 0.6), sea),
                float3(0.1, 0.9, 0.9), side )*float3(3e-3) / (length(p) + ofs);
    small += max(0.,-sign(op.y))*float3(0.004)*(1.0-sea);
    
    return small;
  }

  float a, angle, dist, ii;

  float3 face(float3 p, float t) {
    p.x -= 0.25 ;
    p.y -= 5.05;
    p.z -= 2.0;// - struckfinal*0.6 ;
    
    a=0.0;
    for (ii=0.;ii<1.0;ii+=1./7.0) {
      angle = (ii)*2.*PI + (t - end)*0.5;
      //float angle2 =(i)*2.*PI + PI*0.5;
      dist = 0.24 + sin(t*.5)*(0.05 + struckfinal*0.04) - 0.29*end;
      float3 q = p + 1.0*float3(
                                dist*cos(angle*1.0) + 0.0,
                                dist*sin(angle*1.0) ,
                                0.0					);
      //float3 q = p + float3(0.0, 0.0, 0.0);
      a += 0.8e-2/pow(length(q) * 7.0, 1.0);
    }

    return float3(0.0, 0.5, 1.0)*a;
  }

  float3 field(float3 p, float t) {
    //return mix(max(float3(0.0), space(p, t)), face(p, t), bust);
    //return space(p, t) + face(p, t) * bust * 0.0;
    return mix(face(p,t), space(p, t), intro+struckfinal*0.1);
  }

  float3 origin;
  float rxy, ryz, rxz, orbit, back;
  float3 p, accum, d;
  int iii;

  float3 march(float2 uv, float t) {
    origin = float3(uv - float2(0.5, 0.25), 1.0);
    origin.xy*=0.7;
    
#define ni(x) smootherstep(0.0, 1.0, max(0.0, min(1.0, x)))
    
    orbit = 1.0 - ni((t-50.0)*0.04);
    sea = ni((t-100.0)*0.05);
    seabrite = ni((t-113.0)*0.3);
    buildings2 = 1.0-orbit; // TODO simplify?
    buildings = buildings2-sea;
    startmove = ni((t-7.0)*0.045);
    surface = ni((t-140.0)*0.1);
    spaceboost = ni((t-31.0)*0.18);

    //float back = ni((t-142.0)*0.08);
    back = ni((t-159.0)*0.1); //147
    end = ni((t-185.0)*0.2);
    sea -= back; //ni((t-150.0)*0.1);
    intro = ni((t-8.0)*0.1);
    intro -= back;
    surface -= back*0.9;

    struckfinal = ni((t-175.0)*0.15);
    
    bust = ni((t-30.0)*0.2);

    zofs = t*0.5 + t*buildings2*0.5      - pow(0.015*t, 4.0) - startmove*6.0 - buildings*40.0;;
    
    //intro
    ryz = orbit*0.4 - 0.2 + buildings*0.15 + 0.5;
    rxz = orbit*0.7 + sin(t*0.1)*0.1*sea + sea*0.1;
    
    ryz += buildings*(sin(t*0.1)*0.2-0.1) + 0.1 * surface;

    rxz += buildings*0.8;
    rxz += cos(t*0.1)*0.3*sea  - 0.2*sea;
    ryz -= 0.4 + 0.4*sea + cos(t*0.1)*0.4*sea;
    rxy = -0.2*sea;
    
    origin.xy = pR(origin.xy, rxy * intro);
    origin.yz = pR(origin.yz, ryz * intro);
    origin.xz = pR(origin.xz, rxz * intro);
    
    float3 dir = normalize(origin);
    
    origin.x += 0.25;
    origin.y += 5.0 - sea*7.0;
    
    p = origin;
    accum = float3(0.);
    //int lim = 40 + int(spaceboost*spaceboost)*40;
    for (iii=0;iii<80;iii++) {
      //if (iii > lim) break;
      d = field(p, t);
      accum += d;
      //accum *= mix(0.85, 1.0, spaceboost);

      p += dir * 1.0e-3 * max(0.005, 1.0/length(d));
    }

    float dist = length(p-origin);
    //accum *= 6.0 - 5.0*spaceboost;
    
    accum *= mix(max(0., 1.0 - 0.1*sqrt(dist)), 1.0, buildings);
    accum *= 1.0 + surface*abs(sin(dist * 0.1))*2.0*cos(p.y*0.6);
    //accum *= pow(min(1.0, max(0.0, dist*(0.15))), 2.0);
    //accum *= min(1.0, max(0.0, pow(dist - 10.0, 1.0)*0.05))*4.0;
    //accum = mix(max(float3(0.0), accum - float3(1.0) * max(0.0, sqrt(dist)*5e-2))*1.5, accum, spaceboost);
    accum /= 1.0+buildings*0.4;
    return accum + float3(pow(max(accum.x, max(accum.y, accum.z)), 2.0)); // boost the saturated colors to white
  }

  float t;
  float2 movement, centr;
  float3 stars, bg, newx;
  float noise, feedback;
};

fragmentFn(texture2d<float> lastFrame) {
  shaderName shad;

  shad.t = uni.iTime;
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
  float2 pu = float2(uv.x, uv.y * (uni.iResolution.y/uni.iResolution.x));

  // Time varying pixel color
  //  float3 col = 0.5 + 0.5*cos(uni.iTime+uv.xyx+float3(0,2,4));

  shad.movement = 1e-4*float2(cos(shad.t*.2), sin(shad.t*.2));
  shad.centr = float2(0.5) + shad.movement;


  float3 old = lastFrame.sample(iChannel0, uv ).rgb;
  old += 1.0/255. * rand(uv+float2(shad.t)) - 0.1/255.0;
  float2 ncoord = pu + float2(sin(uni.iTime*199.), sin(uni.iTime*238.));
  shad.noise = shad.snoise(8e2*ncoord);

  shad.stars = pow(shad.march(pu, shad.t), float3(2.0));
  shad.feedback = 0.96 - shad.buildings * 0.2 - 0.5 + shad.struckfinal*0.04;

  shad.newx = shad.feedback*(mix(float3(1.0,0.98,0.99), float3(0.99, 0.95, 0.95), shad.struckfinal)*old) + (0.2 + shad.buildings*0.3)* shad.stars + 0.0*float3(shad.noise-0.5);
  //float3 new = back*0.4 + 0.05*stars;
  shad.newx *= 1.0-shad.end-max(0.,3.0-shad.t);
  shad.newx = clamp(shad.newx, float3(0.0), float3(1.0));
  //new = new*0.001 + float3(uv.x, uv.y, 0.0);
  return float4(shad.newx*2.0,1.0);
}
