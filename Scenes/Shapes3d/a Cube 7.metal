/** 
 Author: Himred
 6 shaders mapped on the 6 faces of a cube without any buffer and using raymarching.
 This is a recode from previous version https://www.shadertoy.com/view/ld2yDz
 which was using rasterization and I decided to redo it using raymarching.
 
 */
#define shaderName a_Cube_7

#include "Common.h"
struct InputBuffer {};
initialize() {}


// 6 shaders mapped on the 6 faces of a cube without any buffer and using raymarching
//
// This is a recode from previous version https://www.shadertoy.com/view/ld2yDz
// which was using rasterization and I decided to redo it using raymarching.
// Using raymarching gives a lot more possibilities than rasterization.
//
// Coded because I love cubes (don't ask me why)
// and also love the retro amiga scene.
//
// The six shaders I love and I used here:
//
// Face 1: WWDC14 by capnslipp - https://www.shadertoy.com/view/XdfyRB
// Face 2: Plasma by Klk - https://www.shadertoy.com/view/XsVSzW
// Face 3: YaraGui by dila - https://www.shadertoy.com/view/ldlyWS
// Face 4: Combustible Voronoi by Shane - https://www.shadertoy.com/view/4tlSzl
// Face 5: Ring twister by Flyguy - https://www.shadertoy.com/view/Xt23z3
// Face 6: Glenz by myself - https://www.shadertoy.com/view/4lt3R7 
//

#define NUM_FACES 4
#define IN_RADIUS 0.25
#define OUT_RADIUS 0.70
#define XSCROLL_SPEED -0.9
#define COLOR_1 0.50, 0.90, 0.95
#define COLOR_2 0.95, 0.60, 0.10
#define BORDER 0.01
#define BORDERCOLOR float4(0.8,0.8,0.8,1.)

constant const float3 xcolor = float3(0.2, 0.5, 1.0);

class shaderName {
public:
  
  float aaSize = 0.0;
  float3 cubevec;
  int id=0;
  float time;
  float2 reso;
  int buttons;
  
  // ---------------- Glenz Shader Code -----------------------
  float3 calcSine(float2 uv, float frequency, float amplitude, float shift, float offset, float3 color, float width, float exponent)
  {
    float y = sin(time * frequency + shift + uv.x) * amplitude + offset;
    //    float d = distance(y, uv.y);
    float scale = smoothstep(width, 0.0, distance(y, uv.y));
    return color * scale;
  }
  
  float3 Bars(float2 uv)
  {
    //float2 uv = f / reso;
    float3 color = float3(0.0);
    color += calcSine(uv, 2.0, 0.25, 0.0, 0.5, float3(0.0, 0.0, 1.0), 0.1, 3.0);
    color += calcSine(uv, 2.6, 0.15, 0.2, 0.5, float3(0.0, 1.0, 0.0), 0.1, 1.0);
    color += calcSine(uv, 0.9, 0.35, 0.4, 0.5, float3(1.0, 0.0, 0.0), 0.1, 1.0);
    return color;
  }
  
  float3 Twister(float3 p)
  {
    float f = sin(time/3.)*1.45;
    float c = cos(f*p.y);
    float s = sin(f/2.*p.y);
    float2x2  m = float2x2(c,-s,s,c);
    return float3(m*p.xz,p.y);
  }
  
  float Cube( float3 p )
  {
    p=Twister(p);
    cubevec.x = sin(time);
    cubevec.y = cos(time);
    float2x2 m = float2x2( cubevec.y, -cubevec.x, cubevec.x, cubevec.y );
    p.xy = p.xy * m;
    p.xy = p.xy * m;
    p.yz = p.yz * m;
    p.zx = p.zx * m;
    p.zx = p.zx * m;
    p.zx = p.zx * m;
    cubevec = p;
    return length(max(abs(p)-float3(0.4),0.0))-0.08;
  }
  
  float Face( float2 uv )
  {
    uv.y = mod( uv.y, 1.0 );
    return ( ( uv.y < uv.x ) != ( 1.0 - uv.y < uv.x ) ) ? 1.0 : 0.0;
  }
  
  float3 getNormal( const float3 p )
  {
    float2 e = float2(0.005, -0.005);
    return normalize(
                     e.xyy * Cube(p + e.xyy) +
                     e.yyx * Cube(p + e.yyx) +
                     e.yxy * Cube(p + e.yxy) +
                     e.xxx * Cube(p + e.xxx));
  }
  
  float4 Glenz(const float2 uv )
  {
    if(uv.x<BORDER || uv.y<BORDER || uv.x>1.-BORDER || uv.y>1.-BORDER) return BORDERCOLOR;
    //    float pat = time*5.0;
    float Step = 1.0;
    float Distance = 0.0;
    float Near = -1.0;
    float Far = -1.0;
    float3 lightPos = float3(1.5, 0, 0);
    float2 p = -1.0 + uv *2.0;
    //    float2 kp=uv;
    // float2 mx = uni.iMouse;
    float hd=-1.;
    
    float3 ro = float3( 0.0, 0.0, 2.1 );
    float3 rd = normalize( float3( p, -2. ) );
    for( int i = 0; i < 256; i++ )
    {
      Step = Cube( ro + rd*Distance );
      Distance += Step*.5;
      
      if( Distance > 4.0 ) break;
      if( Step < 0.001 )
      {
        Far = Face( cubevec.yx ) + Face( -cubevec.yx ) + Face( cubevec.xz ) + Face( -cubevec.xz ) + Face( cubevec.zy ) + Face( -cubevec.zy );
        if(hd<0.) hd=Distance;
        if( Near < 0.0 ) Near = Far;
        if(!buttons) Distance += 0.05; else break; // 0.05 is a magic number
      }
    }
    
    float3 Color=Bars(uv);
    if( Near > 0.0 )
    {
      float3 sp = ro + rd*hd;
      float3 ld = lightPos - sp;
      float lDist = max(length(ld), 0.001);
      ld /= lDist;
      //            float atten = 1./(1. + lDist*.2 + lDist*.1);
      float ambience = 0.7;
      float3 sn = getNormal( sp);
      float diff = min(0.3,max( dot(sn, ld), 0.0));
      float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
      if(!buttons) Color = Color/5. + mix( float3( 0.2, 0.0, 1.0 ), float3( 1.0, 1.0, 1.0 ), float3( ( Near*0.45 + Far*Far*0.04 ) ) );
      else Color = mix( float3( 0.2, 0.0, 1.0 ), float3( 1.0, 1.0, 1.0 ), float3( ( Near*0.45 + Far*Far*0.04 ) ) );
      Color = Color*(diff+ambience)+float3(0.78,0.5,1.)*spec/1.5;
    }
    return float4( Color, 1.0 );
  }
  
  // ---------------- Ring Shader Code -----------------------
  float4 slice(float x0, float x1, float2 uv)
  {
    float u = (uv.x - x0)/(x1 - x0);
    float w = (x1 - x0);
    float3 col = float3(0);
    col = mix(float3(COLOR_1), float3(COLOR_2), u);
    col *= w / sqrt(2.0 * IN_RADIUS*IN_RADIUS * (1.0 - cos(tau / float(NUM_FACES))));
    col *= smoothstep(0.05, 0.10, u) * smoothstep(0.95, 0.90, u) + 0.5;
    uv.y += time * XSCROLL_SPEED; //Scrolling
    col *= (-1.0 + 2.0 * smoothstep(-0.03, 0.03, sin(u*PI*4.0) * cos(uv.y*16.0))) * (1.0/16.0) + 0.7;
    float clip = 0.0;
    clip = (1.0-smoothstep(0.5 - aaSize/w, 0.5 + aaSize/w, abs(u - 0.5))) * step(x0, x1);
    return float4(col, clip);
  }
  
  float4 Ring(  float2 uv)
  {
    if(uv.x<BORDER || uv.y<BORDER || uv.x>1.-BORDER || uv.y>1.-BORDER) return BORDERCOLOR;
    aaSize = 2.0 / reso.y;
    uv = uv * 2.0 - 1.0;
    float2 uvr = float2(length(uv), atan2(uv.y, uv.x) + PI);
    uvr.x -= OUT_RADIUS;
    float3 col = float3(0.05);
    float angle = uvr.y + 2.0*time + sin(uvr.y) * sin(time) * PI;
    
    for(int i = 0;i < NUM_FACES;i++)
    {
      float x0 = IN_RADIUS * sin(angle + tau * (float(i) / float(NUM_FACES)));
      float x1 = IN_RADIUS * sin(angle + tau * (float(i + 1) / float(NUM_FACES)));
      float4 face = slice(x0, x1, uvr);
      col = mix(col, face.rgb, face.a);
    }
    return float4(col, 1.0);
  }
  
  // ---------------- Voronoi Shader Code -----------------------
  float3 firePalette(float i){
    
    float T = 1400. + 1300.*i;
    float3 L = float3(7.4, 5.6, 4.4);
    L = pow(L,float3(5.0)) * (exp(1.43876719683e5/(T*L))-1.0);
    return 1.0-exp(-5e8/L);
  }
  
  float3 hash33(float3 p){
    
    float n = sin(dot(p, float3(7, 157, 113)));
    return fract(float3(2097152, 262144, 32768)*n);
  }
  
  float xvoronoi(float3 p){
    
    float3 b, r, g = floor(p);
    p = fract(p);
    float d = 1.;
    for(int j = -1; j <= 1; j++) {
      for(int i = -1; i <= 1; i++) {
        
        b = float3(i, j, -1);
        r = b - p + hash33(g+b);
        d = min(d, dot(r,r));
        
        b.z = 0.0;
        r = b - p + hash33(g+b);
        d = min(d, dot(r,r));
        
        b.z = 1.;
        r = b - p + hash33(g+b);
        d = min(d, dot(r,r));
        
      }
    }
    
    return d;
  }
  
  float noiseLayers(  float3 p) {
    float3 t = float3(0., 0., p.z+time*1.5);
    
    const int iter = 5;
    float tot = 0., sum = 0., amp = 1.;
    
    for (int i = 0; i < iter; i++) {
      tot += xvoronoi(p + t) * amp;
      p *= 2.0;
      t *= 1.5;
      sum += amp;
      amp *= 0.5;
    }
    return tot/sum;
  }
  
  float4 Voronoi(  float2 uv )
  {
    if(uv.x<BORDER || uv.y<BORDER || uv.x>1.-BORDER || uv.y>1.-BORDER) return BORDERCOLOR;
    uv = uv * 2.0 - 1.0;
    uv += float2(sin(time*0.5)*0.25, cos(time*0.5)*0.125);
    float3 rd = normalize(float3(uv.x, uv.y, PI/8.));
    float cs = cos(time*0.25), si = sin(time*0.25);
    rd.xy = rd.xy*float2x2(cs, -si, si, cs);
    float c = noiseLayers(rd*2.);
    c = max(c + dot(hash33(rd)*2.-1., float3(0.015)), 0.);
    c *= sqrt(c)*1.5;
    float3 col = firePalette(c);
    col = mix(col, col.zyx*0.15+c*0.85, min(pow(dot(rd.xy, rd.xy)*1.2, 1.5), 1.));
    col = pow(col, float3(1.5));
    return float4(sqrt(saturate(col)), 1.);
  }
  
  // ---------------- Plasma Shader Code -----------------------
  float4 Plasma(float2 uv )
  {
    if(uv.x<BORDER || uv.y<BORDER || uv.x>1.-BORDER || uv.y>1.-BORDER) return BORDERCOLOR;
    float tim=time*4.0;
    uv = (uv-0.0)*6.0;
    //    float2 uv0=uv;
    float i0=1.0;
    float i1=1.0;
    float i2=1.0;
    float i4=0.0;
    for(int s=0;s<7;s++)
    {
      float2 r;
      r=float2(cos(uv.y*i0-i4+tim/i1),sin(uv.x*i0-i4+tim/i1))/i2;
      r+=float2(-r.y,r.x)*0.3;
      uv.xy+=r;
      
      i0*=1.93;
      i1*=1.15;
      i2*=1.7;
      i4+=0.05+0.1*tim*i1;
    }
    float r=sin(uv.x-tim)*0.5+0.5;
    float b=sin(uv.y+tim)*0.5+0.5;
    float g=sin((uv.x+uv.y+sin(tim*0.5))*0.5)*0.5+0.5;
    return float4(r,g,b,1.0);
  }
  
  // ---------------- Twirl Shader Code -----------------------
  float4 tw(float2 uv)
  {
    float j = sin(uv.y * PI + time * 5.0);
    float i = sin(uv.x * 15.0 - uv.y * TAU + time * 3.0);
    float n = -clamp(i, -0.2, 0.0) - 0.0 * clamp(j, -0.2, 0.0);
    return 3.5 * (float4(xcolor, 1.0) * n);
  }
  
  float4 Twirl(float2 p)
  {
    if(p.x<BORDER || p.y<BORDER || p.x>1.-BORDER || p.y>1.-BORDER) return BORDERCOLOR;
    float2 uv;
    p=-1.+2.*p;
    
    float r = sqrt(dot(p, p));
    float a = atan2(
                    p.y * (0.3 + 0.1 * cos(time * 2.0 + p.y)),
                    p.x * (0.3 + 0.1 * sin(time + p.x))
                    ) + time;
    
    uv.x = time + 1.0 / (r + .01);
    uv.y = 4.0 * a / PI;
    
    return mix(float4(0.0), tw(uv) * r * r * 2.0, 1.0);
  }
  
  // ---------------- Room Shader Code -----------------------
  
  float udRoundBox( float3 p, float3 b, float r )
  {
    return length(max(abs(p)-b,0.0))-r;
  }
  
  float smin( float a, float b, float k )
  {
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
  }

  float map(float3 p) {
    float k = 0.5 * 2.0;
    float3 q = (fract((p - float3(0.25, 0.0, 0.25))/ k) - 0.5) * k;
    float3 s = float3(q.x, p.y, q.z);
    float d = udRoundBox(s, float3(0.1, 1.0, 0.1), 0.05);
    
    k = 0.5;
    q = (fract(p / k) - 0.5) * k;
    s = float3(q.x, abs(p.y) - 1.5, q.z);
    float g = udRoundBox(s, float3(0.17, 0.5, 0.17), 0.2);
    
    float sq = sqrt(0.5);
    float3 u = p;
    u.xz = u.xz * float2x2(sq, sq, -sq, sq);
    d = max(d, -sdBox(u, float3(0.8, 1.0, 0.8)));
    
    return smin(d, g, 16.0);
  }
  
  float3 normal(float3 p)
  {
    float3 o = float3(0.001, 0.0, 0.0);
    return normalize(float3(map(p+o.xyy) - map(p-o.xyy),
                            map(p+o.yxy) - map(p-o.yxy),
                            map(p+o.yyx) - map(p-o.yyx)));
  }
  
  float trace(float3 o, float3 r) {
    float t = 0.0;
    for (int i = 0; i < 32; ++i) {
      t += map(o + r * t);
    }
    return t;
  }
  
  float4 Room(float2 uv )
  {
    if(uv.x<BORDER || uv.y<BORDER || uv.x>1.-BORDER || uv.y>1.-BORDER) return BORDERCOLOR;
    uv = uv * 2.0 - 1.0;
    uv.x *= reso.x / reso.y;
    
    float gt = time / 5.0;
    float3 r = normalize(float3(uv, 1.7 - dot(uv, uv) * 0.1));
    float sgt = sin(gt * TAU);
    r.xy = r.xy * rot2d(sgt * PI / 8.0);
    r.xz = r.xz * rot2d(PI * 0.0 + gt * TAU);
    r.xz = r.xz * rot2d(PI * -0.25);
    
    float3 o = float3(0.0, 0.0, gt * 5.0 * sqrt(2.0) * 2.0);
    o.xz = o.xz * rot2d(PI * -0.25);
    
    float t = trace(o, r);
    float3 w = o + r * t;
    float3 sn = normal(w);
    float fd = map(w);
    
    float3 col = float3(0.514, 0.851, 0.933) * 0.5;
    float3 ldir = normalize(float3(-1, -0.5, 1.1));
    
    float fog = 1.0 / (1.0 + t * t * 0.1 + fd * 100.0);
    //    float front = max(dot(r, -sn), 0.0);
    float ref = max(dot(r, reflect(-ldir, sn)), 0.0);
    float grn = pow(abs(sn.y), 3.0);
    
    float3 cl = float3(grn);
    cl += mix(col*float3(1.5), float3(0.25), grn) * pow(ref, 16.0);
    cl = mix(col, cl, fog);
    
    return float4(cl, 1.0);
  }
  
  // ---------------- Main Shader Code -----------------------
  float3 Face(float3 p,float3 n,int f )
  {
    n = max(abs(n) - 0.2, 0.001);
    p+=0.5;
    n /= (n.x + n.y + n.z );
    if(f==1) return (Voronoi(p.yz)*n.x + Voronoi(p.zx)*n.y + Voronoi(p.xy)*n.z).xyz;
    if(f==2) return (Ring(p.yz)*n.x + Ring(p.zx)*n.y + Ring(p.xy)*n.z).xyz;
    if(f==3) return (Glenz(p.yz)*n.x + Glenz(p.zx)*n.y + Glenz(p.xy)*n.z).xyz;
    if(f==4) return (Plasma(p.yz)*n.x + Plasma(p.zx)*n.y + Plasma(p.xy)*n.z).xyz;
    if(f==5) return (Twirl(p.yz)*n.x + Twirl(p.zx)*n.y + Twirl(p.xy)*n.z).xyz;
    if(f==6) return (Room(p.yz)*n.x + Room(p.zx)*n.y + Room(p.xy)*n.z).xyz;
    
    return 0;
  }
  
  float Scene(float3 p)
  {
    return max(max(abs(p.x), abs(p.y)), abs(p.z)) - 5.;
  }
  
  float3 Normal(float3 p)
  {
    float3 o = float3(0.01, 0, 0);
    return normalize(float3(Scene(p-o.xyz)-Scene(p+o.xyz),Scene(p-o.zxy)-Scene(p+o.zxy),Scene(p-o.yzx)-Scene(p+o.yzx)));
  }
  
  float3 RayMarch(float3 ro,float3 rd)
  {
    float hd = 0.0;
    id=0;
    for(int i = 0;i < 128;i++)
    {
      float d = Scene(ro + rd * hd);
      hd += d;
      if(d < 0.0001) {id=1; break;}
    }
    return ro + rd * hd;
  }
  
  float3 GetColor(float3 p, float3 n)
  {
    p/=10.;
    if(dot(n,float3(1,0,0))>0.) return Face(p,n,1);
    if(dot(n,float3(1,0,0))<0.) return Face(p,n,2);
    if(dot(n,float3(0,0,1))>0.) return Face(p,n,3);
    if(dot(n,float3(0,0,1))<0.) return Face(p,n,4);
    if(dot(n,float3(0,1,0))>0.) return Face(p,n,5);
    if(dot(n,float3(0,1,0))<0.) return Face(p,n,6);
    return float3(1);
  }
  
  float3 Lightning(float3 sp,float3 sn,float3 rd,float3 lp,float3 color,float3 lc)
  {
    // From a Shane Shader
    float3 ld = lp - sp;
    float lDist = max(length(ld), 0.001);
    ld /= lDist;
    //    float atten = 1./(1. + lDist*.2 + lDist*.1);
    float ambience = 1.;
    float diff = min(0.3,max( dot(sn, ld), 0.0));
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
    return color*(diff+ambience)+lc*spec/1.5;
  }
};

fragmentFn() {
  shaderName shad;
  shad.time = uni.iTime;
  shad.buttons = uni.mouseButtons;
  shad.reso = uni.iResolution;
  
  float2 ratio = uni.iResolution.xy / uni.iResolution.y;
  float2 uv = thisVertex.where.xy / uni.iResolution.y;
  
  float3 ro = float3(0 , 0, -20.0);
  float3 rd = normalize(float3(uv - ratio / 2.0, 1.0));
  
  float2x2 rx = rot2d(uni.iTime);
  float2x2 ry = rot2d(uni.iTime*2.);
  
  ro.yz = ro.yz * rx;
  ro.xz = ro.xz * ry;
  rd.yz = rd.yz * rx;
  rd.xz = rd.xz * ry;
  
  float3 sp = shad.RayMarch(ro, rd);
  float3 sn = shad.Normal(sp);
  float3 color = float3(0);
  
  if(shad.id==1)
  {
    color = shad.GetColor(sp,sn);
    color = shad.Lightning(sp,sn,rd,ro-float3(5),color,float3(1,1,1));
  }
  
  return float4(color, 1.0);
}
