/** 
Author: cxw
Part 09: Basic 3D --- raycasting and simple lighting
Intro to democoding using ShaderToy
By cxw/Incline - Demosplash 2016
*/
#define shaderName demosplash2016_cxw_09

#include "Common.h"
struct InputBuffer { };

initialize() {}


 



// Parameters for your demo.

//Geometry
#define QUAD_SIDE_LEN (2.0)
#define TWOSIDED
#define SHADING_RULE (3)
    // 0=>none, 1=>flat, 2=>Lambertian, 3=>Phong

//View
#define ORBIT_RADIUS (6.0)
#define FOVY_DEG (20.0)
    // Sort of like the zoom on a camera --- smaller is closer

// Material
#define SHININESS (256.0)

// Display physics
#define GAMMA (2.2)
#define ONE_OVER_GAMMA (0.45454545454545454545454545454545)

// Routines /////////////////////////////////////////////////////////////

// BASIC 3D ///////////////////////////////////////////

void lookat(const float3 in_eye, const float3 in_ctr, const float3 in_up,
            thread float4x4& view, thread float4x4& view_inv)
{
    // From Mesa glu.  Thanks to
    // http://learnopengl.com/#!Getting-started/Camera
    // and https://www.opengl.org/wiki/GluLookAt_code

    float3 forward, side, up;

    forward=normalize(in_ctr-in_eye);
    up = in_up;
    side = normalize(cross(forward,up));
    up = cross(side,forward);   // already normalized since both inputs are
        //now side, up, and forward are orthonormal

    float4x4 orient, where;

    // Note: in Mesa gluLookAt, a C matrix is used, so the indices
    // have to be swapped compared to that code.
    float4 x4, y4, z4, w4;
    x4 = float4(side,0);
    y4 = float4(up,0);
    z4 = float4(-forward,0);
    w4 = float4(0,0,0,1);
    orient = transpose(float4x4(x4, y4, z4, w4));

    where = float4x4(1.0); //identity (1.0 diagonal matrix)
    where[3] = float4(-in_eye, 1);

    view = (orient * where);

    // Compute the inverse for later
    view_inv = float4x4(x4, y4, z4, -where[3]);
    view_inv[3][3] = 1.0;   // since -where[3].w == -1, not what we want
        // Per https://en.wikibooks.org/wiki/GLSL_Programming/Vertex_Transformations ,
        // M_{view->world}
} //lookat

void gluPerspective(const float fovy_deg, const float aspect,
                    const float near, const float far,
                    thread float4x4& proj, thread float4x4& proj_inv)
{   // from mesa glu-9.0.0/src/libutil/project.c.
    // Thanks to https://unspecified.wordpress.com/2012/06/21/calculating-the-gluperspective-matrix-and-other-opengl-matrix-maths/

    float fovy_rad = radians(fovy_deg);
    float dz = far-near;
    float sin_fovy = sin(fovy_rad);
    float cot_fovy = cos(fovy_rad) / sin_fovy;

    proj=float4x4(0);
    //[col][row]
    proj[0][0] = cot_fovy / aspect;
    proj[1][1] = cot_fovy;

    proj[2][2] = -(far+near)/dz;
    proj[2][3] = -1.0;

    proj[3][2] = -2.0*near*far/dz;

    // Compute the inverse matrix.
    // http://bookofhook.com/mousepick.pdf
    float a = proj[0][0];
    float b = proj[1][1];
    float c = proj[2][2];
    float d = proj[3][2];
    float e = proj[2][3];

    proj_inv = float4x4(0);
    proj_inv[0][0] = 1.0/a;
    proj_inv[1][1] = 1.0/b;
    proj_inv[3][2] = 1.0/e;
    proj_inv[2][3] = 1.0/d;
    proj_inv[3][3] = -c/(d*e);
} //gluPerspective

void compute_viewport(const float x, const float y, const float w, const float h,
                        thread float4x4& viewp, thread float4x4& viewp_inv)
{
    // See https://en.wikibooks.org/wiki/GLSL_Programming/Vertex_Transformations#Viewport_Transformation
    // Also mesa src/mesa/main/viewport.c:_mesa_get_viewport_xform()

    viewp = float4x4(0);
    // Reminder: indexing is [col][row]
    viewp[0][0] = w/2.0;
    viewp[3][0] = x+w/2.0;

    viewp[1][1] = h/2.0;
    viewp[3][1] = y+h/2.0;

    // assumes n=0 and f=1,
    // which are the default for glDepthRange.
    viewp[2][2] = 0.5;  // actually 0.5 * (f-n);
    viewp[3][2] = 0.5;  // actually 0.5 * (n+f);

    viewp[3][3] = 1.0;

    //Invert.  Done by hand.
    viewp_inv = float4x4(1.0);
    viewp_inv[0][0] = 2.0/w;    // x->x
    viewp_inv[3][0] = -1.0 - (2.0*x/w);

    viewp_inv[1][1] = 2.0/h;    // y->y
    viewp_inv[3][1] = -1.0 - (2.0*y/h);

    viewp_inv[2][2] = 2.0;      // z->z
    viewp_inv[3][2] = -1.0;

}  //compute_viewport

// RAYCASTING /////////////////////////////////////////

float4 wts(const float4x4 modelviewproj, const float4x4 viewport,
                const float3 pos)
{   // world to screen coordinates
    float4 clipvertex = modelviewproj * float4(pos,1.0);
    float4 ndc = clipvertex/clipvertex.w;
    float4 transformed = viewport * ndc;
    return transformed;
} //wts

// screen to world: http://bookofhook.com/mousepick.pdf
float4 WorldRayFromScreenPoint(const float2 scr_pt,
    const float4x4 view_inv,
    const float4x4 proj_inv,
    const float4x4 viewp_inv)
{   // Returns world coords of a point on a ray passing through
    // the camera position and scr_pt.

    float4 ndc = viewp_inv * float4(scr_pt,0.0,1.0);
        // z=0.0 => it's a ray.  0 is an arbitrary choice in the
        // view volume.
        // w=1.0 => we don't need to undo the perspective divide.
        //      So clip coords == NDC

    float4 view_coords = proj_inv * ndc;
        // At this point, z=0 will have become something in the
        // middle of the projection volume, somewhere between
        // near and far.
    view_coords = view_coords / view_coords.w;
        // Keepin' it real?  Not sure what happens if you skip this.
    //view_coords.w = 0.0;
        // Remove translation components.  Note that we
        // don't use this trick.
    float4 world_ray_point = view_inv * view_coords;
        // Now scr_pt is on the ray through camera_pos and world_ray_point
    return world_ray_point;
} //WorldRayFromScreenPoint

// HIT-TESTING ////////////////////////////////////////

float3 HitZZero(float3 camera_pos, float3 rayend)
{   // Find where the ray meets the z=0 plane.  The ray is
    // camera_pos + t*(rayend - camera_pos) per Hook.
    float hit_t = -camera_pos.z / (rayend.z - camera_pos.z);
    return (camera_pos + hit_t * (rayend-camera_pos));
} //HitZZero

// --- IsPointInRectXY ---
// All polys will be quads in the X-Y plane, Z=0.
// All quad edges are parallel to the X or Y axis.
// These quads are encoded in a float4: (.x,.y) is the LL corner and
// (.z,.w) is the UR corner (coords (x,y)).

bool IsPointInRectXY(const float4 poly_coords, const float2 world_xy_of_point)
{
    // return true if world_xy_of_point is within the poly defined by
    // poly_coords in the Z=0 plane.
    // I can test in 2D rather than 3D because all the geometry
    // has z=0 and all the quads are planar.

    float x_test, y_test;
    x_test = step(poly_coords.x, world_xy_of_point.x) *
            (1.0 - step(poly_coords.z, world_xy_of_point.x));
        // step() is 1.0 if world.x >= poly_coords.x
        // 1-step() is 1.0 if world.x < poly_coords.z
    y_test = step(poly_coords.y, world_xy_of_point.y) *
            (1.0 - step(poly_coords.w, world_xy_of_point.y));

    return ( (x_test>=0.9) && (y_test >= 0.9) );
        // Not ==1.0 because these are floats!

} //IsPointInRectXY

// CAMERA AND LIGHT ///////////////////////////////////

float3 pos_clelies(const float time, const float radius)
{   //Clelies curve
    //thanks to http://wiki.roblox.com/index.php?title=Parametric_equations
    float3 pos; float m = 0.8;
    float smt = sin(m*time);
    pos.x = radius * smt*cos(time);
    pos.y = radius * smt*sin(time);
    pos.z = radius * cos(m*time);
    return pos;
} //camerapos

void get_cam_and_light(
    const float time,
    thread float3& camera_pos, thread float3& camera_look_at, thread float3& camera_up,
    thread float& fovy_deg, thread float3& light_pos)
{
    camera_pos = pos_clelies(time, ORBIT_RADIUS);
    camera_look_at = float3(0.0);
    camera_up = float3(0.0, 1.0, 0.0);
    fovy_deg = FOVY_DEG;
    light_pos = camera_pos;
} //get_cam_and_light

// SHADING ////////////////////////////////////////////

float lambertian_shade(const float3 pixel_pos, const float3 normal,
                    const float3 light_pos, const float3 camera_pos)
{ //Lambertian shading.  Returns the reflectance visible at camera_pos as a
  //result of lighting pixel_pos (having normal) from light_pos.  
  //One-sided object.

    float3 light_dir = normalize(light_pos - pixel_pos);
    float3 eye_dir = normalize(camera_pos - pixel_pos);
    if(dot(light_dir, eye_dir) < 0.0) {
        return 0.0;     // Camera behind the object => no reflectance
    } else {
        return max(0.0, dot(light_dir, normal));
            // ^^^^^^^^ light behind the object => no reflectance
    }
} //lambertian_shade

float3 phong_color(
    const float3 pixel_pos, const float3 normal, const float3 camera_pos,      // Scene
    const float3 light_pos, const float3 ambient_color,                   // Lights
    const float3 diffuse_color, const float3 specular_color,              // Lights
    const float shininess)                                         // Material
{   // Compute pixel color using Phong shading.  Modified from
    // https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model
    // normal must be normalized on input.  All inputs are world coords.
    // Set shininess <=0 to turn off specular highlights.
    // Objects are one-sided.

    float3 light_dir = normalize(light_pos - pixel_pos);
    float3 eye_dir = normalize(camera_pos - pixel_pos);

    if(dot(light_dir, eye_dir) < 0.0) {
        return ambient_color;       // Camera behind the object
    }

    float lambertian = max(0.0, dot(light_dir, normal));        // Diffuse

    float specular = 0.0;
    if((lambertian > 0.0) && (shininess > 0.0)) {               // Specular
        float3 reflectDir = reflect(-light_dir, normal);
        float specAngle = max(dot(reflectDir, eye_dir), 0.0);
        specular = pow(specAngle, shininess);
    }
    /*
    return pow(ambient_color + lambertian*diffuse_color + specular*float3(1.0),
                float3(ONE_OVER_GAMMA));
        // TODO Do I need this?
    */
    lambertian = pow(lambertian, ONE_OVER_GAMMA);
    specular = pow(specular, ONE_OVER_GAMMA);

    float3 retval = ambient_color + lambertian*diffuse_color + 
        specular*specular_color;

    return saturate(retval);     // no out-of-range values, please!

} //phong_color

// mainImage() //////////////////////////////////////////////////////////

fragmentFn()
{
    float time = uni.iTime;
//    float2 pixel_coord_01 = thisVertex.where.xy.xy / uni.iResolution.xy;

    // --- Camera and light ---
    float3 camera_pos, camera_look_at, camera_up, light_pos;
    float fovy_deg;

    get_cam_and_light(time,
        camera_pos, camera_look_at, camera_up, fovy_deg, light_pos);

    // Camera processing

    float4x4 view, view_inv;
    lookat(camera_pos, camera_look_at, camera_up,
            view, view_inv);

    float4x4 proj, proj_inv;            // VVVVVVVVV squares are square! :)
    gluPerspective(fovy_deg, uni.iResolution.x/uni.iResolution.y, 1.0, 10.0,
                    proj, proj_inv);

    float4x4 viewport, viewport_inv;    // VVVVVVVVV squares are square! :)
    compute_viewport(0.0, 0.0, uni.iResolution.x, uni.iResolution.y,
                        viewport, viewport_inv);

    float3 material_color = float3(0.0);    //Color of the quad before shading

    // Raycasting

    float3 rayend = WorldRayFromScreenPoint(thisVertex.where.xy,
                                    view_inv, proj_inv, viewport_inv).xyz;
        // rayend-camera_pos is the direction of the ray
    float3 world_xyz0_of_point = HitZZero(camera_pos, rayend);
        // Where the ray hits z=0
    float3 normal = float3(0.0,0.0,-1.0 + 2.0*step(0.0, camera_pos.z));
        // normal Z is -1 if camera_pos.z<0.0, and +1 otherwise.

    // Hit-testing
    float qh = QUAD_SIDE_LEN*0.5;
    float4 theshape = float4(-qh,-qh,qh,qh);

    if(IsPointInRectXY(theshape, world_xyz0_of_point.xy)) {

#ifndef TWOSIDED
        material_color = float3(1.0);
#else
        float front_view = step(0.0, camera_pos.z);
        material_color = float3(front_view, 0.0, 1.0-front_view);
#endif

    } else {    //we didn't hit
        return float4(0.0,0.0,0.0,1.0);  //black
            // comment out the "return" for a chuckle
    }

    // Shading (it's a shader, after all!)

#if SHADING_RULE == 0
    fragColor = float4(material_color, 1.0);                  //No shading

#elif SHADING_RULE == 1
    // Flat shading - per-poly
    float reflectance = // VVVVVVV per-poly, lighting as a the poly's center.
        lambertian_shade(float3(0.0), normal, light_pos, camera_pos);

    float reflectance_gc = pow(reflectance, ONE_OVER_GAMMA);
        // Gamma-correct luminous-intensity reflectance into monitor space.
        // Hey, it's just math, right?  I did this because the quad was too
        // dark otherwise.

    // White light for simplicity
    fragColor = float4(reflectance_gc * material_color, 1.0);

#elif SHADING_RULE == 2
    //Lambertian shading
    float reflectance = //     VVV Lambertian is per-point, not per-poly
        lambertian_shade(world_xyz0_of_point, normal, light_pos, camera_pos);

    float reflectance_gc = pow(reflectance, ONE_OVER_GAMMA);
    return float4(reflectance_gc * material_color, 1.0);

#else
    // Phong shading
    float3 ambient_color = float3(0.1);
    float3 specular_color = float3(1.0);
    float3 color = phong_color(
        world_xyz0_of_point, normal, camera_pos, light_pos, 
        ambient_color, material_color, specular_color,  // Light colors
        SHININESS);

    return float4(color, 1.0);
#endif
} //mainImage

