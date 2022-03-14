/** 
Author: BigWIngs
If you want to really get sad then be sure to watch with sound  ;)
If you want to see and control the rain, comment out the HAS_HEART define
Controls: Mouse x = scrub time  y = rain amount (only without heart)
*/
#define shaderName Heartfelt

#include "Common.h"

struct InputBuffer {
  bool HAS_HEART = true;
  bool USE_POST_PROCESSING = true;
  bool CHEAP_NORMALS = false;
};

initialize() {
}

static float3 N13(float p) {
    //  from DAVE HOSKINS
   float3 p3 = fract(float3(p) * float3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

static float N(float t) {
    return fract(sin(t*12345.564)*7658.76);
}

static float Saw(float b, float t) {
	return smoothstep(0., b, t)*smoothstep(1., b, t);
}


static float2 DropLayer2(float2 uv, float t) {
    float2 UV = uv;
    
    uv.y += t*0.75;
    float2 a = float2(6., 1.);
    float2 grid = a*2.;
    float2 id = floor(uv*grid);
    
    float colShift = N(id.x); 
    uv.y += colShift;
    
    id = floor(uv*grid);
    float3 n = N13(id.x*35.2+id.y*2376.1);
    float2 st = fract(uv*grid)-float2(.5, 0);
    
    float x = n.x-.5;
    
    float y = UV.y*20.;
    float wiggle = sin(y+sin(y));
    x += wiggle*(.5-abs(x))*(n.z-.5);
    x *= .7;
    float ti = fract(t+n.z);
    y = (Saw(.85, ti)-.5)*.9+.5;
    float2 p = float2(x, y);
    
    float d = length((st-p)*a.yx);
    
    float mainDrop = smoothstep(.4, .0, d);
    
    float r = sqrt( smoothstep(1., y, st.y));
    float cd = abs(st.x-x);
    float trail = smoothstep(.23*r, .15*r*r, cd);
    float trailFront = smoothstep(-.02, .02, st.y-y);
    trail *= trailFront*r*r;
    
    y = UV.y;
    float trail2 = smoothstep(.2*r, .0, cd);
    float droplets = max(0., (sin(y*(1.-y)*120.)-st.y))*trail2*trailFront*n.z;
    y = fract(y*10.)+(st.y-.5);
    float dd = length(st-float2(x, y));
    droplets = smoothstep(.3, 0., dd);
    float m = mainDrop+droplets*r*trailFront;
    
    //m += st.x>a.y*.45 || st.y>a.x*.165 ? 1.2 : 0.;
    return float2(m, trail);
}

static float StaticDrops(float2 uv, float t) {
	uv *= 40.;
    
    float2 id = floor(uv);
    uv = fract(uv)-.5;
    float3 n = N13(id.x*107.45+id.y*3543.654);
    float2 p = (n.xy-.5)*.7;
    float d = length(uv-p);
    
    float fade = Saw(.025, fract(t+n.z));
    float c = smoothstep(.3, 0., d)*fract(n.z*10.)*fade;
    return c;
}

static float2 Drops(float2 uv, float t, float l0, float l1, float l2) {
    float s = StaticDrops(uv, t)*l0; 
    float2 m1 = DropLayer2(uv, t)*l1;
    float2 m2 = DropLayer2(uv*1.85, t)*l2;
    
    float c = s+m1.x+m2.x;
    c = smoothstep(.3, 1., c);
    
    return float2(c, max(m1.y*l0, m2.y*l1));
}

fragmentFn(texture2d<float> tex)
{
	float2 uv = worldCoordAspectAdjusted / 2;
    float2 UV = textureCoord;
    float3 M = float3(uni.iMouse.xy, 1);
    float T = uni.iTime+M.x*2.;
    
  if (in.HAS_HEART) {
    T = mod(uni.iTime, 102.);
    T = mix(T, M.x*102., M.z>0.?1.:0.);
  }
    
    
    float t = T*.2;
    
    float rainAmount = uni.mouseButtons ? M.y : sin(T*.05)*.3+.7;
    
    float maxBlur = mix(3., 6., rainAmount);
    float minBlur = 2.;
    
    float story = 0.;
    float heart = 0.;

  float zoom;
  if (in.HAS_HEART) {
    story = smoothstep(0., 70., T);
    
    t = min(1., T/70.);						// remap drop time so it goes slower when it freezes
    t = 1.-t;
    t = (1.-t*t)*70.;
    
    zoom= mix(.3, 1.2, story);		// slowly zoom out
    uv *=zoom;
    minBlur = 4.+ smoothstep(.5, 1., story)*3.;		// more opaque glass towards the end
    maxBlur = 6.+ smoothstep(.5, 1., story)*1.5;
    
    float2 hv = uv-float2(.0, -.1);				// build heart
    hv.x *= .5;
    float s = smoothstep(110., 70., T);				// heart gets smaller and fades towards the end
    hv.y-=sqrt(abs(hv.x))*.5*s;
    heart = length(hv);
    heart = smoothstep(.4*s, .2*s, heart)*s;
    rainAmount = heart;						// the rain is where the heart is
    
    maxBlur-=heart;							// inside the heart slighly less foggy
    uv *= 1.5;								// zoom out a bit more
    t *= .25;
  } else {
    zoom = -cos(T*.2);
    uv *= .7+zoom*.3;
  }

    UV = (UV-.5)*(.9+zoom*.1)+.5;
    
    float staticDrops = smoothstep(-.5, 1., rainAmount)*2.;
    float layer1 = smoothstep(.25, .75, rainAmount);
    float layer2 = smoothstep(.0, .5, rainAmount);
    
    
    float2 c = Drops(uv, t, staticDrops, layer1, layer2);
  float2 n;
  if (in.CHEAP_NORMALS) {
    	n = float2(dfdx(c.x), dfdy(c.x));// cheap normals (3x cheaper, but 2 times shittier ;))
  } else {
    	float2 e = float2(.001, 0.);
    	float cx = Drops(uv+e, t, staticDrops, layer1, layer2).x;
    	float cy = Drops(uv+e.yx, t, staticDrops, layer1, layer2).x;
    	n = float2(cx-c.x, cy-c.x);		// expensive normals
  }
    
    
  if (in.HAS_HEART) {
    n *= 1.-smoothstep(60., 85., T);
    c.y *= 1.-smoothstep(80., 100., T)*.8;
  }
    
    float focus = mix(maxBlur-c.y, minBlur, smoothstep(.1, .2, c.x));
    float3 col = textureLod(tex, iChannel0, UV+n, focus).rgb;
    
    
  if (in.USE_POST_PROCESSING) {
    t = (T+3.)*.5;										// make time sync with first lightnoing
    float colFade = sin(t*.2)*.5+.5+story;
    col *= mix(float3(1.), float3(.8, .9, 1.3), colFade);	// subtle color shift
    float fade = smoothstep(0., 10., T);              // fade const at the start
    float lightning = sin(t*sin(t*10.));				// lighting flicker
    lightning *= pow(max(0., sin(t+sin(t))), 10.);		// lightning flash
    col *= 1.+lightning*fade*mix(1., .1, story*story);	// composite lightning
  UV -= .5;
    col *= 1.-dot(UV, UV);							// vignette
    											
  if (in.HAS_HEART) {
    	col = mix(pow(col, float3(1.2)), col, heart);
    	fade *= smoothstep(102., 97., T);
  }
    
    col *= fade;										// composite start and end fade
  }
    
    //col = float3(heart);
    return float4(col, 1.);
}
