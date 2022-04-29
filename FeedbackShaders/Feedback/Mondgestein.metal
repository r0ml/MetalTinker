/** 
Author: pyBlob
portal clone

porting works!
place portals: q/e

doing: portal gun (... sort of working)
todo: fix portal collision (jumping)
todo: material for stairs + portal border
todo: seperate rendering + game logic
*/

#define shaderName mondgestein

#include "Common.h" 

struct InputBuffer {
  };

initialize() {
  // setTex(0, asset::granite);
}

 



const float2 res = float2(480, 270);

fragmentFn(texture2d<float> tex) {
	float2 uv = thisVertex.where.xy.xy / uni.iResolution.xy * (res / uni.iResolution.xy);
    
	fragColor = renderPass[0].sample(iChannel0, uv);
    
    uv = (thisVertex.where.xy.xy - uni.iResolution.xy/0.5) / uni.iResolution.yy;
    fragColor = mix(fragColor, float4(1), saturate((0.2-length(uv))*uni.iResolution.y));
    
    //fragColor = float4(1.0);
    //fragCol/Volumes/Media/Repositories/GPUTinker/Shaders/Fragment/Mo/Mondgestein.metalor -= float4(saturate(0.9 - 0.1*length(thisVertex.where.xy.xy - uni.iMouse.xy)));
    //fragColor -= float4(saturate(0.8 - 0.05*length(thisVertex.where.xy.xy - uni.iMouse.zw)));
    //fragColor = uni.iMouse.z<0.0 ? float4(1.0) : float4(0.0);
}



 // ============================================== buffers ============================= 

tClass( a)

 //#define AO

const float2 res = float2(480, 270);

const float VK_LEFT  = 37.0;
const float VK_UP    = 38.0;
const float VK_RIGHT = 39.0;
const float VK_DOWN  = 40.0;
const float VK_A     = 65.0;
const float VK_W     = 87.0;
const float VK_D     = 68.0;
const float VK_S     = 83.0;
const float VK_E     = 69.0;
const float VK_Q     = 81.0;

const float var_base = res.y;

#define var(v, x, y)  const float2 v = float2(x, y)+0.5;
var(GI_POS    , 3, var_base)
var(GI_LOOK   , 1, var_base)
var(GI_LOOKLOCK, 2, var_base)
var(GI_LASTPOS, 0, var_base)
var(GI_PORTAL1, 4, var_base)
var(GI_PORTAL2, 5, var_base)

float4 load(float2 v)
{
    return inTexture.sample(iChannel0, v / uni.iResolution);
}

bool keyDown(uint key)
{
  return uni.keyPress.x == key ;
}

bool test(float a, float b)
{
    return a-0.5 < b && a+0.5 > b;
}
bool test(float2 a, float2 b)
{
    return test(a.x, b.x);
}

float3x3 setCamera(float2 look)
{
    float2 swap = float2(1.0, -1.0);
    float4 cs1 = float4(cos(look.x), sin(look.x), 0.0, 1.0);
    float4 cs2 = float4(cos(look.y), sin(look.y), 0.0, 1.0);
    
    return
         float3x3(
            cs2.xzy * swap.xxy,
            cs2.zwz,
            cs2.yzx
        )
        *
        float3x3(
        	cs1.wzz,
            cs1.zxy,
            cs1.zyx * swap.xyx
        )
        ;
}

float4 sphere(float3 pos, float radius)
{
    return float4(
        length(pos) - radius,
        normalize(pos)
    );
}

float4 box(float3 pos, float3 size)
{
    float3 d = abs(pos) - size;
    return float4(
        min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)),
        normalize(pos)
    );
}

float3x3 turn(float3 t1, float3 t2)
{
    return float3x3(
        t1,
        t2,
        cross(t1, t2)
    );
}

#define union(a, b) if (b.x < a.x) a = b
#define sect(a, b) if (b.x > a.x) a = b

struct Portal
{
    float3 pos;
    float3 normal;
    float3 up;
    float3 right;
};

Portal p1, p2;

float3x3 warp1;
float3x3 warp2;

int warpColor = 0;
float3 mapdir;
float3 mappos;

bool loaded = false;

float4 mapRaw(float3 pos)
{
    float4 res = float4(1000, 0, 0, 0);
    
    union(res, -box(pos - float3(0,2,0), float3(6,2,10)));
    sect(res, -box(pos - float3(16,2,0), float3(6,2,10)));
    sect(res, -box(pos - float3(8,1,-5), float3(3,1,1)));
    sect(res, -box(pos - float3(8,1,5), float3(3,1,1)));
    
    union(res, sphere(pos - float3(0,1,-4), 1.0));
    union(res, box(pos - float3(-3,1,4), float3(1,1,1)));
    union(res, box(pos - float3(-3,1,7), float3(3,1,3)));
    
    float3 steps = pos - float3(-3,0.9,1.0);
    float offset = floor(steps.z/1.0+0.5)*1.0;
    float4 rstep = box(float3(steps.x, steps.y - 0.5*offset - 0.1*(steps.z-offset), steps.z-offset), float3(1,0.1,0.2));
    
    steps.z += 0.5;
    offset = floor(steps.z/1.0+0.5)*1.0;
    union(rstep, box(steps - float3(0, 0.5*(offset-0.5) + 0.0*(steps.z-offset), offset), float3(1,0.1,0.2)));
    
    steps.z -= 0.5;
    sect(rstep, box(steps, float3(1,1,2)));
    
    rstep.x *= 0.9;
    union(res, rstep);
    
    if (loaded)
    {
        if (warpColor != 2)
        {
            float3 delta = (pos - p1.pos) * warp1;
            delta.z *= 2.0;
            float4 warpRes = float4(length(float2(delta.x, length(delta.yz)-0.9))-0.1, float3(0.0));
         	union(res, warpRes);
            //union();
            if (length(delta) < 1.0)
            {
                res = warpRes;
                if (delta.x < 0.0)
                {
            		delta.z/=2.0;
                    mappos = (warp2 * delta) + p2.pos;
                    mapdir = warp2 * mapdir * warp1;
                    warpColor = 1;
                }
            }
            //union(res, sphere(delta, 1.0));
        }
        if (warpColor != 1)
        {
            float3 delta = (pos - p2.pos) * warp2;
            delta.z *= 2.0;
            float4 warpRes = float4(length(float2(delta.x, length(delta.yz)-0.9))-0.1, float3(0.0));
            union(res, warpRes);
            if (length(delta) < 1.0)
            {
                res = warpRes;
                if (length(delta) < 1.0 && delta.x > 0.0)
                {
            		delta.z/=2.0;
                    mappos = (warp1 * delta) + p1.pos;
                    mapdir = warp1 * mapdir * warp2;
                    warpColor = 2;
                }
            }
            //union(res, sphere(delta, 1.0));
        }
        //union(res, sphere(pos - p1.pos, 0.1));
        //union(res, sphere(pos - p2.pos, 1.0));
    }
    
    return res;
}

float4 map(float3 pos)
{
    warpColor = 0;
    
    return mapRaw(pos);
}

float4 map2(float3 pos)
{
    return mapRaw(pos);
}

float3 getNormal(float3 pos)
{
    // float4 kk;
    float2 e = float2(1.0,-1.0)*0.5773 * 1e-4;
    return normalize(
        e.xyy*map( pos + e.xyy ).x +
        e.yyx*map( pos + e.yyx ).x +
        e.yxy*map( pos + e.yxy ).x +
        e.xxx*map( pos + e.xxx ).x
    );
}

float4 render(float3 pos, float3 dir)
{
    float4 res = float4(0);
    float travel = 0.0;
    
    warpColor = 0;
    for (int i=0 ; i<32 ; i++)
    {
        mappos = pos;
        mapdir = dir;
        res = map2(pos);
        pos = mappos;
        dir = mapdir;
        
        pos += dir * res.x;
        travel += res.x;
    }
    
    float3 normal = getNormal(pos);
    float2 smap = float2(0,0);
    smap += float2(dot(normal, float3(pos.z,0,0)), 0.5*dot(normal, float3(pos.y,0,0)));
    smap += float2(dot(normal, float3(0,pos.x,0)), dot(normal, float3(0,pos.z,0)));
    smap += float2(dot(normal, float3(0,0,pos.x)), 0.5*dot(normal, float3(0,0,pos.y)));
    
#ifdef AO
    float ao = 0.0;
    for (float i=-1.5 ; i<=1.5 ; i++)
    {
        for (float j=-1.5 ; j<=1.5 ; j++)
        {
            for (float k=-1.5 ; k<=1.5 ; k++)
            {
                float3 v = 0.5*float3(i,j,k);
                ao += max(map(pos+v).x, 0.0) / 0.5;
            }
        }
    }
#else
    float ao = 35.0;
#endif
    
    float bias = -5.0+log(travel)/log(1.9);
    float3 color = texture[0].sample(iChannel0, 0.2*smap, bias).xyz;
    color = mix(color, float3(1), 0.7);
    float2 coff = fract(smap);
    
    bias = 2.0 / (travel);
    color = mix(color, float3(0), (1.0-min(1.0, (35.0-2.0*travel)*min(min(coff.x, coff.y),min(1.0-coff.x, 1.0-coff.y))))*bias );
    //color = ;
    
    return
        mix(
            //float4((0.5+0.5*res.yz) / (1.0+0.3*travel), 0.0, 1.0),
            float4(saturate(ao/30.0) * color, 1.0),
            float4(1.0),
            saturate((travel - 2.0) / 25.0)
        );
}

fragmentFn(texture2d<float> tex) {
    if (thisVertex.where.xy.y>=res.y+1.0)
    {
        return;
    }
    
    float3 playerPos = load(GI_POS).xyz;
    float3 lastPos = load(GI_LASTPOS).xyz;
    
    float2 look = load(GI_LOOK).xy;
    float3x3 camera = setCamera(look);
    
    p1.pos = load(GI_PORTAL1).xyz;
    p1.normal = getNormal(p1.pos);
    p1.up = abs(p1.normal.y) > 0.5 ? float3(1,0,0) : float3(0,1,0);
    p1.right = normalize(cross(p1.normal, p1.up));
    warp1 = float3x3(
        p1.normal,
        p1.up,
        p1.right
    );
    
    p2.pos = load(GI_PORTAL2).xyz;
    p2.normal = -getNormal(p2.pos);
    p2.up = abs(p2.normal.y) > 0.5 ? float3(1,0,0) : float3(0,1,0);
    p2.right = normalize(cross(p2.normal, p2.up));
    warp2 = float3x3(
        p2.normal,
        p2.up,
        p2.right
    );
    
    loaded = true;
    
    if (test(thisVertex.where.xy.y, var_base+0.5))
    {
        if (iFrame == 0)
        {
            playerPos = float3(3.5,1.5,-4);
            lastPos = playerPos;
            look = float2(0.0, -0.35);
            
            p1.pos = float3(5.99,1,-0.5);
            p2.pos = float3(-1,1,3.99);
        }
        else if (thisVertex.where.xy.x < 10.0)
        {
    		float2 lastMouse = load(GI_LOOK).zw;
            
            float2 delta = (uni.iMouse.yx - lastMouse.yx) ;
            if (length(delta) < 0.1)
            {
            	look += 3.0 * delta * float2(-1,1);
                look.x = clamp(look.x, -1.57, 1.57);
            }
            
            float2 move = 5.0 * uni.iTimeDelta * float2(
                                                    (keyDown(KEY_RIGHT) || keyDown('d') ? 1 : 0) - (keyDown(KEY_LEFT) || keyDown('a') ? 1 : 0),
                                                    (keyDown(KEY_UP) || keyDown('w') ? 1 : 0) - (keyDown(KEY_DOWN) || keyDown('s') ? 1 : 0)
            );
            
            float3 dir = (playerPos-lastPos) * pow(0.02, uni.iTimeDelta);
            float3 walk = camera[0] * move.x + cross(camera[0], float3(0,1,0)) * move.y;
            dir.xz += 0.5 * (walk.xz-dir.xz);
            dir += saturate(uni.iTime) * float3(0,-1,0) * uni.iTimeDelta;
            
            playerPos += dir;
            
            mappos = playerPos;
            mapdir = dir;
            map(playerPos);
            playerPos = mappos;
            lastPos = playerPos - dir;
            if (warpColor != 0)
            {
                float3 dir = camera[2];
                if (warpColor == 1)
                {
                    dir = warp2 * dir * warp1;
                }
                else
                {
                    dir = warp1 * dir * warp2;
                }
                look = float2(
                    atan2(-dir.y, length(dir.xz)),
                    atan2(dir.x, dir.z)
                    
                );
            }
            
            {
            	float3 boundpos = playerPos + float3(0,0.4,0);
            	float3 normal = getNormal(boundpos);
            	playerPos -= min(map(boundpos).x - 0.4, 0.0) * normal;
            }
            {
            	float3 boundpos = playerPos + float3(0,0.6,0);
            	float3 normal = getNormal(boundpos);
            	playerPos -= min(map(boundpos).x - 0.4, 0.0) * normal;
            }
        }
        
        if (test(thisVertex.where.xy, GI_POS))
        {
            fragColor.xyz = playerPos;
        }
        else if (test(thisVertex.where.xy, GI_LOOK))
        {
            fragColor = float4(look, uni.iMouse.xy * uni.iResolution);
        }
        else if (test(thisVertex.where.xy, GI_LASTPOS))
        {
            fragColor.xyz = lastPos;
        }
        else if (test(thisVertex.where.xy, GI_PORTAL1))
        {
            if (uni.iTime > fragColor.w && keyDown('q') )
            {
                loaded = false;
                fragColor.w = uni.iTime + 1.0;
                mappos = playerPos+float3(0,1.5,0);
                mapdir = camera[2];
                for (int i=0 ; i<32 ; i++)
                {
                    float4 x = map(mappos);
                    mappos += mapdir * x.x;
                }
                p1.pos = mappos;
                
            }
            fragColor.xyz = p1.pos;
        }
        else if (test(thisVertex.where.xy, GI_PORTAL2))
        {
            if (uni.iTime > fragColor.w && keyDown('e') )
            {
                loaded = false;
                fragColor.w = uni.iTime + 1.0;
                mappos = playerPos+float3(0,1.5,0);
                mapdir = camera[2];
                for (int i=0 ; i<32 ; i++)
                {
                    float4 x = map(mappos);
                    mappos += mapdir * x.x;
                }
                p2.pos = mappos;
                
            }
            fragColor.xyz = p2.pos;
        }
    }
    else if (thisVertex.where.xy.x < res.x)
    {
		float2 uv = (thisVertex.where.xy.xy - res.xy*0.5) / res.yy;
        
        fragColor = render(playerPos+float3(0,1.5,0), camera * normalize(float3(uv,0.5)));
		//fragColor = float4(float3(saturate(length(5.0*uv-playerPos.xy))),1.0);
        //fragColor = texture(iChannel2, uv*float2(-1,1)+0.5);
    }
}

tRun 
