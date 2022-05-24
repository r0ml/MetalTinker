/** 
 Author: jfuchs
 My first attempt at 3D graphics programming. Made for my first quarter project in my senior year high school programming class. Amateur programming all around; feedback much appreciated.
 */
#define shaderName a_Cube_11

#include "Common.h"

struct InputBuffer {
  };

initialize() {
// setTex(0, asset::pebbles);
}


class shaderName {
public:
  float time;
  
  float4 quatMultiply(float4 q1, float4 q2){
    return float4(q1.x*q2.x - dot(q1.yzw, q2.yzw), q1.yzw*q2.x + q2.yzw*q1.x + cross(q1.yzw, q2.yzw));
  }
  
  float3 quatRotate(float3 p, float4 q){
    return quatMultiply(quatMultiply(q, float4(0, p)),float4(q.x, -q.yzw)).yzw;
  }
  
  //Quaternion maths courtesy of http://www.3dgep.com/understanding-quaternions/
  
  void initPoints(float3 size, float4 orientation){
    //Four points are needed to define a cuboid.
    points[0] = -size;
    points[1] = float3(size.x, -size.yz);
    points[2] = float3(-size.x, size.y, -size.z);
    points[3] = float3(-size.xy, size.z);
    for(int i = 0; i < 4; i++){
      points[i] = quatRotate(points[i], orientation);
    }
  }
  
  void initFaces() {
    //Faces are planes defined by <a, b, c, d>, where ax + by + cz + d = 0.
    //The boundaries of the faces are determined by the points.
    float3 normal = cross(points[1] - points[0], points[2] - points[0]);
    faces[0] = float4(normal, -dot(normal, points[0]));
    faces[3] = float4(faces[0].xyz, faces[0].w - dot(normal, points[3] - points[0]));
    normal = cross(points[2] - points[0], points[3] - points[0]);
    faces[1] = float4(normal, -dot(normal, points[0]));
    faces[4] = float4(faces[1].xyz, faces[1].w - dot(normal, points[1] - points[0]));
    normal = cross(points[3] - points[0], points[1] - points[0]);
    faces[2] = float4(normal, -dot(normal, points[0]));;
    faces[5] = float4(faces[2].xyz, faces[2].w - dot(normal, points[2] - points[0]));
  }
  
  float4 background(){
    //Lame shifting color background to fill up the rest of the screen.
    float4 backColor = float4(1,1,1,1);
    float t15 = mod(time, 15.0);
    float t5 = mod(time, 5.0);
    float3 colorShift = float3(cos(0.314*t5), sin(0.314*t5), 0);
    if(t15 < 5.0) backColor -= colorShift.xyzz;
    else if(t15 < 10.0) backColor -= colorShift.zxyz;
    else backColor -= colorShift.yzxz;
    backColor.xyz /= 4.0;
    return backColor;
  }
  
  float4 castRay(float3 dir, float3 points[4], float4 faces[6], float4 colors[6], texture2d<float> tex0){
    //I opted for plain raycasting instead of raymarching because I thought it would improve perfomance.
    //But I'm a terrible graphics programmer, so that didn't turn out to be the case. Oh well.
    
    float3 u[6]; float3 v[6];
    //The components of the faces. There has to be a better way to do this...
    u[0] = points[1] - points[0]; v[0] = points[2] - points[0];
    u[1] = points[2] - points[0]; v[1] = points[3] - points[0];
    u[2] = points[3] - points[0]; v[2] = points[1] - points[0];
    u[3] = points[0] - points[1]; v[3] = points[0] - points[2];
    u[4] = points[0] - points[2]; v[4] = points[0] - points[3];
    u[5] = points[0] - points[3]; v[5] = points[0] - points[1];
    
    const float3 camera = float3(0, 0, 5);
    float minT = 1e20;
    int bestFace = -1;
    float bestA;
    float bestB;
    
    for(int i = 0; i < 6; i++){ //Iterating over the faces.
      float t = -(faces[i].w + dot(faces[i].xyz, camera))/(dot(faces[i].xyz, dir));
      //The distance to the point of intersection with a face. I guess the formula works?
      if(t < minT && t > 0.0){
        float3 p = camera + dir*t; //The actual point of intersection.
        if(i < 3) p = p - points[0];
        else p = p + points[0];
        //...And adjusting it so that the following formulas will work.
        float a = (p.x*v[i].y - p.y*v[i].x)/(u[i].x*v[i].y - u[i].y*v[i].x);
        float b = (p.x*u[i].y - p.y*u[i].x)/(u[i].y*v[i].x - u[i].x*v[i].y);
        //a and b are the distances along the face components to the point.
        //I would use matrices here, but I don't know any linear algebra :(
        if(a >= 0.0 && a < 1.0 && b >= 0.0 && b < 1.0){
          //Checking to see if the point of intersection is actually on the face.
          minT = t;
          bestFace = i;
          bestA = a;
          bestB = b;
        }
      }
    }
    //What do you mean, non-constant array indices aren't allowed? Guess there's this workaround...
    for(int i = 0; i < 6; i++){
      if(bestFace == i) return tex0.sample(iChannel0, float2(bestA, bestB)) * colors[i];
      //Finally returning the point on the face intersecting the ray.
    }
    return background();
  }
  
  float3 points[4];
  float4 faces[6];
};

fragmentFn(texture2d<float> tex) {
  shaderName shad;
  shad.time = uni.iTime;
  
  float3 size = float3(1.0, 1.0, 1.0);
  float4 colors[6];
  colors[0] = float4(0.8,0.5,0.5,1); colors[1] = float4(0.5,0.8,0.5,1); colors[2] = float4(0.5,0.5,0.8,1);
  colors[3] = float4(0.5,0.8,0.8,1); colors[4] = float4(0.8,0.5,0.8,1); colors[5] = float4(0.8,0.8,0.5,1);
  
  
  float t3 = mod(shad.time, 3.0);
  float t1 = mod(shad.time, 1.0);
  float2 deform = float2(sin(PI*t1)/2.0, -sin(PI*t1)/3.0);
  float3 lightup = float3(sin(PI*t1)/5.0, -sin(PI*t1)/2.0, 0);
  //Performing the stretchy and light-up effects.
  if(t3 < 1.0){
    size += deform.yyx;
    colors[0] += lightup.xyyz;
    colors[3] += lightup.yxxz;
  }
  else if(t3 < 2.0){
    size += deform.xyy;
    colors[1] += lightup.yxyz;
    colors[4] += lightup.xyxz;
  }
  else{
    size += deform.yxy;
    colors[2] += lightup.yyxz;
    colors[5] += lightup.xxyz;
  }
  
  float angle = shad.time;
  float3 rotAxis = normalize(float3(cos(shad.time/3.0),sin(shad.time/3.0),-sin(shad.time/3.0))); //Chaotic rotation
  float4 rotQuat = float4(cos(angle), sin(angle)*rotAxis);
  
  shad.initPoints( size, rotQuat); //Initializing points...
  shad.initFaces(); //Initializing faces...
  float2 fov = thisVertex.where.xy / uni.iResolution.y;
  fov = fov - float2(uni.iResolution.x/uni.iResolution.y/2.0, 0.5); //Calculating field of view...
  return shad.castRay(float3(fov, -1), shad.points, shad.faces, colors, tex); //Done! :D
}
