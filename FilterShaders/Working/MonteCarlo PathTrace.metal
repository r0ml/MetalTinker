/**
 Author: xdaimon
 WIP
 still in early stages of learning monte carlo path tracing.
 */

#define shaderName montecarlo_pathtrace

#include "Common.h" 

struct KBuffer {
};

initialize() {}

// ============================================= common =================================

// Define here so I can copy from my desktop shader viewer easier
#define iRes uni.iResolution.xy
#define iMouseLastDownPos uni.iMouse.xy

 



fragmentFn() {
    float2 p = thisVertex.where.xy / uni.iResolution.xy;
    fragColor = renderPass[0].sample(iChannel0, p);
    fragColor.rgb = pow(fragColor.rgb / fragColor.a, float3(1./2.2));
}


 // ============================================== buffers ============================= 

tClass(a)

 //vim: set foldmethod=marker foldmarker={,}

//#define REFLECTIVE
#define NSAMPLES 3

float sat(float x) {
    return saturate(x);
}

// For smaller input rangers like audio tick or 0-1 UVs use these...
#define HASHSCALE1 443.8975
#define HASHSCALE3 float3(443.897, 441.423, 437.195)
#define HASHSCALE4 float3(443.897, 441.423, 437.195, 444.129)

float hash11(float p) {
    float3 p3  = fract(float3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash12(float2 p) {
    float3 p3  = fract(float3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float2 hash21(float p) {
    float3 p3 = fract(float3(p) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float2 hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// Returns a random number in the range [0,1]
float my_seed = 1.; // set this in main()
float get_rand() {
    my_seed += .01;
    return hash11(my_seed);
}

float2 randDir(float range, float shift) {
    float rand = get_rand();
    return float2(cos(rand*range + shift), sin(rand*range + shift));
}

#define DID_NOT_HIT 10.
#define RO_ON_CIRCLE 0.

float intersectCircle(float2 ro, float2 rd, float2 so, float sr) {
    float2 oc = ro - so;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sr*sr;
    if (c < 0.)
        return RO_ON_CIRCLE;
    float h = b*b - c;
    if (h < 0.)
        return DID_NOT_HIT;
    h = sqrt(h);

    float t0 = -b-h;
    if (t0 > 0.) // do not intersect backward
        return t0;
    float t1 = -b+h;
    if (t1 > 0.)
        return t1;

    return DID_NOT_HIT;
}

/*
if o is in the box, then intersects the box
if o is not in the box, then will give weird results
*/
float intersectBox(float2 o, float2 d, float2 b) {
    float t1 = (b.x-o.x)/d.x;
    float t2 = (-b.x-o.x)/d.x;
    float t3 = (b.y-o.y)/d.y;
    float t4 = (-b.y-o.y)/d.y;
    float t = 100000.;
    if (t1 > 0. && t1 < t) t = t1;
    if (t2 > 0. && t2 < t) t = t2;
    if (t3 > 0. && t3 < t) t = t3;
    if (t4 > 0. && t4 < t) t = t4;
    return t;
}

float min3(float x, float y, float z) {
    return min(x,min(y,z));
}

float min4(float x, float y, float z, float w) {
    return min(min(x,y), min(z,w));
}

/*
float2 V;
#define neat_rot_macro(a) float2x2( V= sin(float2(PI*0.5, 0) + a), -V.y, V.x)
*/

// these are all global so they can easily be displayed for debugging (has been useful)
float3 acc_p1 = float3(0);
float3 ind_p1 = float3(0);
float3 dir_p1 = float3(0);
float3 alb_p1 = float3(0);
float3 inc_p1 = float3(0);

float3 acc_p2 = float3(0);
float3 ind_p2 = float3(0);
float3 dir_p2 = float3(0);
float3 alb_p2 = float3(0);
float3 inc_p2 = float3(0);

float3 acc_p3 = float3(0);
float3 ind_p3 = float3(0);
float3 dir_p3 = float3(0);
float3 alb_p3 = float3(0);
float3 inc_p3 = float3(0);

float lh;
float sh1;
float sh2;
float sh3;
float wh;

bool is_p1_in_shadow;
bool is_p2_in_shadow;
bool is_p3_in_shadow;
float2 p_to_light;
float nearest;

float2 ro_p1;
float2 rd_p1;
float2 n_p1;

float2 ro_p2;
float2 rd_p2;
float2 n_p2;

float2 ro_p3;
float2 rd_p3;
float2 n_p3;

float aspect;
float2 uv;
float2 mouse;
float2 jitter;

float2 lo; // TODO make a torus shaped light
float lr = .125;
float li = 50.;
float lheight = .333;

// occluders
float2 so1 = float2(0,.5);
float sr1 = .3333;
float2 so2 = float2(-.5);
float sr2 = .3333;
float2 so3 = float2(.5,-.5);
float sr3 = .3333;

float2 wall_dim;

// colors
float3 gc = float3(.4);
float3 wc = float3(.2);
float3 sc1 = float3(0,.04,.46);
float3 sc2 = float3(.46,0,.04);
float3 sc3 = float3(.5/3.);
float3 lc = float3(1);

//void computeHitProperties(inout float2 ro, inout float2 rd, out float2 n, out float2 alb)
//void shadowRay(float2 ro, float2

// RAY 2
void get_col_r2() {
    // compute hit and surface properties at hit
    sh1 = intersectCircle(ro_p2,rd_p2,so1,sr1);
    sh2 = intersectCircle(ro_p2,rd_p2,so2,sr2);
    sh3 = intersectCircle(ro_p2,rd_p2,so3,sr3);
    wh = intersectBox(ro_p2,rd_p2,wall_dim);
    nearest = min4(sh1, sh2, sh3, wh);
    if (sh1 == nearest) {
        ro_p3 = ro_p2 + rd_p2 * sh1;
        n_p3 = normalize(ro_p3 - so1);
        alb_p3 = sc1;
        rd_p3 = randDir(PI, atan2(n_p3.y, n_p3.x) - PI / 2.);
    }
    else if (sh2 == nearest) {
        ro_p3 = ro_p2 + rd_p2 * sh1;
        n_p3 = normalize(ro_p3 - so2);
        alb_p3 = sc2;
        rd_p3 = randDir(PI, atan2(n_p3.y, n_p3.x) - PI / 2.);
    }
    else if (sh3 == nearest) {
        ro_p3 = ro_p2 + rd_p2 * sh1;
        n_p3 = normalize(ro_p3 - so3);
        alb_p3 = sc3;
        rd_p3 = randDir(PI, atan2(n_p3.y, n_p3.x) - PI / 2.);
    }
    else if (wh == nearest) {
        ro_p3 = ro_p2 + rd_p2 * wh;
        if (abs(ro_p3.x) / aspect > abs(ro_p3.y)) {
            n_p3 = float2(-sign(ro_p3.x), 0.); // fails to compile w/ weird error if 0 instead of 0.
            rd_p3 = randDir(PI, -n_p3.x * PI / 2.);
        }
        else {
            n_p3 = float2(0, -sign(ro_p3.y));
            rd_p3 = randDir(PI * n_p3.y, 0.);
        }
        alb_p3 = wc;
    }
    #ifdef REFLECTIVE
    rd_p3 = reflect(n_p3, rd_p2);
    #endif
    // push away from the surface a bit.
    // add a bit of randomness to make sure there are no anomalies
    ro_p3 = ro_p3 + .001 * (rd_p3 + jitter);

    // no indirect light for last ray

    // compute direct light
    is_p3_in_shadow = true; // is light visible from p1
    p_to_light = normalize(lo - ro_p3);
    lh = intersectCircle(ro_p3,p_to_light,lo,lr);
    sh1 = intersectCircle(ro_p3,p_to_light,so1,sr1);
    sh2 = intersectCircle(ro_p3,p_to_light,so2,sr2);
    sh3 = intersectCircle(ro_p3,p_to_light,so3,sr3);
    wh = intersectBox(ro_p3,p_to_light,wall_dim);
    nearest = min4(sh1, sh2, sh3, wh);
    if (lh < nearest) {
        is_p3_in_shadow = false;
    }
    if (!is_p3_in_shadow) {
        //if (lh == RO_ON_CIRCLE)
        //    lh = 0.;
        lh = sqrt(lh*lh + lheight*lheight); // figure that light is above the ground
        float falloff = sat(1. / (4. * PI * lh * lh));
        // TODO scale accoring to size of light in hemisphere
        dir_p3 = .5 * lc * li * falloff;
    }

    inc_p3 = ind_p3 * 2. * PI * max(0., dot(n_p3, rd_p3)) + dir_p3 / PI * max(0., dot(n_p3, p_to_light));
    acc_p3 = alb_p3 * inc_p3;
}

// RAY 1
void get_col_r1() { 
    // ray 1 is the first ray sent away from the uv coord

    ind_p2 = float3(0);
    for (int i = 0; i < NSAMPLES; ++i) {
        // compute hit and surface properties at hit
        sh1 = intersectCircle(ro_p1,rd_p1,so1,sr1);
        sh2 = intersectCircle(ro_p1,rd_p1,so2,sr2);
        sh3 = intersectCircle(ro_p1,rd_p1,so3,sr3);
        if (sh1 == RO_ON_CIRCLE) sh1 = DID_NOT_HIT; // prevent self intersections
        if (sh2 == RO_ON_CIRCLE) sh2 = DID_NOT_HIT;
        if (sh3 == RO_ON_CIRCLE) sh3 = DID_NOT_HIT;
        wh = intersectBox(ro_p1,rd_p1,wall_dim);
        nearest = min4(sh1, sh2, sh3, wh);
        if (sh1 == nearest) {
            ro_p2 = ro_p1 + rd_p1 * sh1;
            n_p2 = normalize(ro_p2 - so1);
            alb_p2 = sc1;
            rd_p2 = randDir(PI, atan2(n_p2.y, n_p2.x) - PI / 2.);
        }
        else if (sh2 == nearest) {
            ro_p2 = ro_p1 + rd_p1 * sh2;
            n_p2 = normalize(ro_p2 - so2);
            alb_p2 = sc2;
            rd_p2 = randDir(PI, atan2(n_p2.y, n_p2.x) - PI / 2.);
        }
        else if (sh3 == nearest) {
            ro_p2 = ro_p1 + rd_p1 * sh3;
            n_p2 = normalize(ro_p2 - so3);
            alb_p2 = sc3;
            rd_p2 = randDir(PI, atan2(n_p2.y, n_p2.x) - PI / 2.);
        }
        else if (wh == nearest) {
            ro_p2 = ro_p1 + rd_p1 * wh;
            if (abs(ro_p2.x) / aspect > abs(ro_p2.y)) {
                n_p2 = float2(-sign(ro_p2.x), 0.); // fails to compile w/ weird error if 0 instead of 0.
                rd_p2 = randDir(PI, -n_p2.x * PI / 2.);
            }
            else {
                n_p2 = float2(0, -sign(ro_p2.y));
                rd_p2 = randDir(PI * n_p2.y, 0.);
            }
            alb_p2 = wc;
        }
        #ifdef REFLECTIVE
        rd_p2 = reflect(n_p2,rd_p1);
        #endif
        // push away from the surface a bit.
        // add a bit of randomness to make sure there are no anomalies
        ro_p2 = ro_p2 + .001 * (rd_p2 + jitter);

        // compute indirect light
        get_col_r2();
        ind_p2 += acc_p3 * max(0., dot(n_p2, rd_p2));
    }
    ind_p2 /= float(NSAMPLES);

    // compute direct light // TODO treats light as point light but should treat light as having size
    is_p2_in_shadow = true; // is light visible from p1
    p_to_light = normalize(lo - ro_p2);
    lh = intersectCircle(ro_p2,p_to_light,lo,lr);
    sh1 = intersectCircle(ro_p2,p_to_light,so1,sr1);
    sh2 = intersectCircle(ro_p2,p_to_light,so2,sr2);
    sh3 = intersectCircle(ro_p2,p_to_light,so3,sr3);
    wh = intersectBox(ro_p2,p_to_light,wall_dim);
    nearest = min4(sh1, sh2, sh3, wh);
    if (lh < nearest) {
        is_p2_in_shadow = false;
    }
    if (!is_p2_in_shadow) {
        //if (lh == RO_ON_CIRCLE)
        //    lh = 0.;
        lh = sqrt(lh*lh + lheight*lheight); // figure that light is above the ground
        float falloff = sat(1. / (4. * PI * lh * lh));
        dir_p2 = .5 * lc * li * falloff;
    }

    inc_p2 = ind_p2 * 2. * PI + dir_p2 / PI * max(0., dot(n_p2, p_to_light));
    acc_p2 = alb_p2 * inc_p2;
}

// RAY 0
float3 get_color(const float2 fragP) {
    // ray 0 is the first ray and is simply the uv coord

    // this is the second ray which has it's tail (ro) at the uv coord (head of ro_p0, the first ray)
    ro_p1 = uv + jitter;

    ind_p1 = float3(0);
    for (int i = 0; i < NSAMPLES; ++i) {
        // compute surface properties, how will this point reflect light? ray 1 cannot hit wall
        if (distance(ro_p1, so1) <= sr1) { // hit occluder
            n_p1 = normalize(ro_p1 - so1);
            alb_p1 = sc1;
            rd_p1 = randDir(PI, atan2(n_p1.y, n_p1.x) - PI / 2.);
        }
        else if (distance(ro_p1, so2) <= sr2) { // hit occluder
            n_p1 = normalize(ro_p1 - so2);
            alb_p1 = sc2;
            rd_p1 = randDir(PI, atan2(n_p1.y, n_p1.x) - PI / 2.);
        }
        else if (distance(ro_p1, so3) <= sr3) { // hit occluder
            n_p1 = normalize(ro_p1 - so3);
            alb_p1 = sc3;
            rd_p1 = randDir(PI, atan2(n_p1.y, n_p1.x) - PI / 2.);
        }
        else { // hit floor, can only be intersected on ray 1
            rd_p1 = randDir(2.*PI, 0.);
            n_p1 = rd_p1;
            alb_p1 = gc;
        }
        #ifdef REFLECTIVE
        float range = .333;
        rd_p1 = randDir(range * PI, -PI * range / 2. + atan2(n_p1.y, n_p1.x));
        #endif
        
        // compute indirect light (recurse)
        get_col_r1();
        ind_p1 += acc_p2 * max(0., dot(n_p1, rd_p1));
    }
    ind_p1 /= float(NSAMPLES);
    
    // compute direct light
    is_p1_in_shadow = true; // is light visible from ro_p1
    p_to_light = normalize(lo - ro_p1);
    lh = intersectCircle(ro_p1,p_to_light,lo,lr);
    sh1 = intersectCircle(ro_p1,p_to_light,so1,sr1);
    sh2 = intersectCircle(ro_p1,p_to_light,so2,sr2);
    sh3 = intersectCircle(ro_p1,p_to_light,so3,sr3);
    if (sh1 == RO_ON_CIRCLE) sh1 = DID_NOT_HIT;
    if (sh2 == RO_ON_CIRCLE) sh2 = DID_NOT_HIT;
    if (sh3 == RO_ON_CIRCLE) sh3 = DID_NOT_HIT;
    wh = intersectBox(ro_p1,p_to_light,wall_dim);
    nearest = min4(sh1, sh2, sh3, wh);
    if (lh < nearest) {
        is_p1_in_shadow = false;
    }
    if (!is_p1_in_shadow) {
        //if (lh == RO_ON_CIRCLE)
        //    lh = 0.;
        lh = sqrt(lh*lh + lheight*lheight); // figure that light is above the ground
        float falloff = sat(1. / (4. * PI * lh * lh));
        // TODO scale according to size of light in hemisphere
        dir_p1 = .03 * lc * li * falloff;
    }

    inc_p1 = ind_p1 * 2. * PI + dir_p1 / PI * max(0., dot(n_p1, p_to_light));
    acc_p1 += alb_p1 * inc_p1;

    return acc_p1;

    // DEBUGGING and just neat
    //return acc_p2;
    //return acc_p3;
    //return ind_p1;
    //return dir_p1;
    //return float3(dot(n_p1, rd_p1));
    //return ind_p2 / PI;
    //return dir_p2 / PI / 16.;
    //return ind_p3; // zero
    //return dir_p3 / PI / 16.;
    //return alb_p1;
    //return alb_p2;
    //return alb_p3;
    //return float3(!is_p1_in_shadow);
    //return float3(!is_p2_in_shadow);
    //return float3(!is_p3_in_shadow);
    //return float3(ro_p1.x,0,ro_p1.y);
    //return float3(ro_p2.x,0,ro_p2.y);
    //return float3(ro_p3.x,0,ro_p3.y);
    //return float3(rd_p1.x,0,rd_p1.y);
    //return float3(rd_p2.x,0,rd_p2.y);
    //return float3(rd_p3.x,0,rd_p3.y);
    //return float3(n_p1.x,0,rd_p1.y);
    //return float3(n_p2.x,0,n_p2.y);
    //return float3(n_p3.x,0,n_p3.y);
    //return float3(p_to_light.x,0,p_to_light.y);
    //return iRes.y*float3(jitter.x,0,jitter.y);
    //return 10.*float3(randDir(2.*PI,0.), 0); // scene geometry shows through if this return is used (and if only 2 rays traced for some reason)
}

fragmentFn() {
    float2 fragP = thisVertex.where.xy / iRes;
    float4 oc = renderPass[0].sample(iChannel0, fragP);

    my_seed = hash12(fragP * (1.+mod(uni.iTime,16.)));
    aspect = iRes.x / iRes.y;

    uv = fragP * 2. - 1.;
    uv.x *= aspect;

    mouse = iMouseLastDownPos / iRes * 2. - 1.;
    mouse.x *= aspect;
    if (mouse.x < -.999 && mouse.y < -.999)
        mouse = float2(0, .77);

    // light
    lo = mouse;
    
    wall_dim = float2(aspect, 1.); // half width, half height
    
    jitter = randDir(2.*PI, 0.) / iRes.y;

    float3 col = get_color(fragP);

    //if (iMouseDown || iFrame == 0) {
    //    C.rgb = mix(oc.rgb, col / float(ITERS), float3(.2));
    //    C.a = 1.;
    //}
    //else {
    //    C.rgb = mix(oc.rgb, col / float(ITERS), float3(.2));
    //    C.a = 1.;
    //}
 
    if (uni.mouseButtons || iFrame == 0) {
        oc = float4(0);
    }
    fragColor = oc + float4(col, 1);
}

tRun


