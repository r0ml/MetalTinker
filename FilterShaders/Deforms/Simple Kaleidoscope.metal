
#define shaderName simple_kaleidoscope

#include "Common.h" 

struct InputBuffer {
    struct {
      bool _1;
      bool _2;
      bool _3;
      bool _4;
      bool _5;
      bool _6;
      bool _7;
      bool _8;
      bool _9;
      bool _10;
    } style;
};

initialize() {
//  setTex(0, asset::pebbles);
  in.style._1 = 1;
}

static float2 loop(float2 uv, float c, float s, float q, uint n) {
//  const float q = mt * .2 / tau;
  for ( uint i=0; i<n; i++ ) {
    float t = q * atan2(uv.x,uv.y);
    t = abs(fract(t*.5+.5)*2.0-1.0) / q;
    uv = length(uv)*float2(sin(t),cos(t)) - 0.7;
    uv = uv*c + s*uv.yx*float2(1,-1);
  }
  return uv;
}

static float de(float3 p) {
  return length(cos(p)+2.0)-1.0;
}

static float3 transform1(float3 p, float time) {
  float atime = time*0.3;

  float3 ro = 3.0*float3(cos(atime), 0, -sin(atime));
  float3 ww = normalize(float3(0, sin(time), 0) - ro);
  float3 uu = normalize(cross(float3(0, 1, 0), ww));
  float3 vv = normalize(cross(ww, uu));
  float3 rd = normalize(uu*p.x + vv*p.y + 1.97*ww);

  float3 col = float3(1.0);

  float t = 0.0;

  for(int i = 0; i < 16; i++) {
    float d = de(ro + rd*t);
    if(d < 0.001*t || t >= 10.0) break;
    t += d;
  }

  float3 pos = float3(0.0);
  pos = ro + rd*t;
  float2 h = float2(0.001, 0.0);
  float3 nor = normalize(float3(
                                de(pos + h.xyy) - de(pos - h.xyy),
                                de(pos + h.yxy) - de(pos - h.yxy),
                                de(pos + h.yyx) - de(pos - h.yyx)
                                ));
  col = nor;

  return nor;
}

static float3 hash(float x) { return fract(sin((float3(x)+float3(23.32445,132.45454,65.78943))*float3(23.32445,32.45454,65.78943))*4352.34345); }

static float3 noise(float x)
{
  float p = fract(x); x-=p;
  return mix(hash(x),hash(x+1.0),p);
}

static float3 noiseq(float x) {
  return (noise(x)+noise(x+10.25)+noise(x+20.5)+noise(x+30.75))*0.25;
}

static float2 polarRep(float2 U, float n) {
  n = TAU/n;
  float a = atan2(U.y, U.x),
  r = length(U);
  a = mod(a+n/2.,n) - n/2.;
  U = r * float2(cos(a), sin(a));
  return .5* ( U+U - float2(1,0) );
}

static float2x2 mat2x(float4 x) { return float2x2(x.xy, x.zw); }

constant const int SIDES = 5;

static float2 ro(float2 p, float a) {
  float4 z = cos(a + .8*float4(6,0,0,2));
  return p * float2x2(z.xy, z.zw);
}

static float m(float3 p, float t) {
  p.z -= t * 2;
  p = mod(p, 2.)-1.;
  p *= .5;
  p.xy = ro(p.xy, p.z + t);
  return length(max(abs(p)-.5*float3(.5, .3, .8), 0.));
}

fragmentFn(texture2d<float> tex) {
//  float2 uv = (thisVertex.where.xy-.5*uni.iResolution.xy) * 7.2 / uni.iResolution.y;
  float2 uv = worldCoordAspectAdjusted * 3.6;
  const float mt = mix(uni.iTime, uni.iTime * .3 + 10, in.style._3);

  const float r = 1.0;
  const float a = mt*.1;
  const float c = cos(a)*r;
  const float s = sin(a)*r;

  if (in.style._1) {
    for ( int i=0; i<32; i++ )  {
      uv = abs(uv);
      uv -= .25;
      uv = uv*c + s*uv.yx*float2(1,-1);
    }
  } else if (in.style._2) {
    const float q = 7. / tau;
    uv = loop(uv, c, s, q, 10);
  } else if (in.style._3) {
    const float q = mt * .2 / tau;
    uv = loop(uv, c, s, q, 30);
  } else if (in.style._4) {
    float2 p = worldCoordAspectAdjusted;
    float4 fragColor = 0;
    for (int c = 0; c < 3; c++) {
      for (float s = 1.; s > .2; s *= .8 ) {
        fragColor[c] += s * .064 / length( p = ( abs(p) / dot(p, p) - s ) * makeMat(cos( uni.iTime*.5+.05*float(c) + float4(0,33,11,0))) );
      }
    }
    fragColor.w = 1;
    return fragColor;
  } else if (in.style._5) {
    float3 p = float3(worldCoordAspectAdjusted, 0);

    float3 col = float3(0.0);
    float fog = 1.0;
    for(int i = 0; i < 4; i++) {
      p = transform1(p, uni.iTime);
      col += saw(p*2.0);
      fog /= log(abs(p.z)+1.0)+1.0;
    }
    //   int t = int(saw(time)*1.9);
    return float4( col*fog, 1);
  } else if (in.style._6) {
    float time=uni.iTime*0.15;
    float3 k1=noiseq(time)*float3(0.1,0.19,0.3)+float3(1.3,0.8,.63);
    float3 k2=noiseq(time+1000.0)*float3(0.2,0.2,0.05)+float3(0.9,0.9,.05);
    //float k3=clamp(texture(iChannel0,float2(0.01,0.)).x,0.8,1.0); float k4=clamp(texture(iChannel0,float2(0.2,0.)).x,0.5,1.0); k2+=float3((k3-0.8)*0.05); k1+=float3((k4-0.5)*0.01);
    float g=pow(abs(sin(time*0.8+9000.0)),4.0);

    float2 R = uni.iResolution.xy;

    float2 r1=(thisVertex.where.xy / R.y-float2(0.5*R.x/R.y,0.5));
    float l = length(r1);
    float2 rotate=float2(cos(time),sin(time));
    r1=float2(r1.x*rotate.x+r1.y*rotate.y,r1.y*rotate.x-r1.x*rotate.y);
    float2 c3 = abs(r1.xy/l);
    if (c3.x>0.5) c3=abs(c3*0.5+float2(-c3.y,c3.x)*0.86602540);
    c3=normalize(float2(c3.x*2.0,(c3.y-0.8660254037)*7.4641016151377545870));

    float4 fragColor = float4(c3*l*70.0*(g+0.12), .5,0);
    for (int i = 0; i < 128; i++) {
      fragColor.xzy = (k1 * abs(fragColor.xyz/dot(fragColor,fragColor)-k2));
    }
    fragColor.w = 1;
    return fragColor;

  } else if (in.style._7) {
    float2 U = worldCoordAspectAdjusted;
    float t = uni.iTime/5.;
    float n = 10.* (.5-.5*cos(TAU*t));

    for( float i=0.; i < mod(t,4.); i++) {
      U = polarRep(U, n);
    }

    return tex.sample(iChannel0, .5+U);
  } else if (in.style._8) {
    // set position
    float2 v = uni.iResolution.xy;
    float2 p = (thisVertex.where.xy-v*.5)*.4 / v.y;
    // breathing effect
    p += p * sin(dot(p, p)*20.-uni.iTime) * .04;


    float4 fragColor = 0;
    // accumulate color

    for (float i = .5 ; i < 8. ; i++)

      // fractal formula and rotation
      p = abs(2.*fract(p-.5)-1.) * mat2x(cos(.01*(uni.iTime+uni.iMouse.x*uni.iResolution.x*.1)*i*i + .78*float4(1,7,3,1))),

      // coloration
      fragColor += exp(-abs(p.y)*5.) * (cos(float4(2,3,1,0)*i)*.5+.5);



    // palette
    fragColor.gb *= .5;
    fragColor.w = 1;
    return fragColor;

  } else if (in.style._9) {
    float2 uv = worldCoordAspectAdjusted / 2;

    uv *= 3.0;

    float4 fragColor = 0;

    for (int i = 0 ; i < 7 ; i++) {

      float scaleFactor = float(i)+2.0;

      // rotation
      uv *= rot2d(uni.iTime * scaleFactor * 0.01);

      // polar transform
      const float scale = 2.0*PI/float(SIDES);
      float theta = atan2(uv.x, uv.y)+PI;
      theta = (floor(theta/scale)+0.5)*scale;
      float2 dir = float2(sin(theta), cos(theta));
      float2 codir = dir.yx * float2(-1, 1);
      uv = float2(dot(dir, uv), dot(codir, uv));

      // translation
      uv.x -= uni.iTime * scaleFactor * 0.01;

      // repetition
      uv = abs(fract(uv+0.5)*2.0-1.0)*0.7;

      // coloration
      fragColor.rgb += exp(-min(uv.x, uv.y)*10.) * (cos(float3(2,3,1)*float(i)+uni.iTime*0.5)*.5+.5);

    }

    fragColor.rgb *= 0.4;
    fragColor.a = 1.0;
    return fragColor;

  } else if (in.style._10) {
    float2 g = -abs(worldCoordAspectAdjusted);
    float3 r = float3(0, 0, 1), d = float3(g, -1), p;
    d.xz = ro(d.xz, uni.iDate.w);
    d.yz = ro(d.yz, - uni.iDate.w);
    d.xy = ro(d.xy, uni.iDate.w );
    float t = 0., h;
    for (int i = 0; i < 99; i++) {
      p = r + d * t;
      h = m(p, uni.iDate.w);
      t += h;
      if (h < .005 || t > 40.) break;
    }
    return float4(abs(p), 1);

  }
  
  return float4(.5+.5*sin(mt+float3(13,17,23)*tex.sample( iChannel0, uv*float2(1,-1)+.5, -1.0 ).rgb), 1);
}
