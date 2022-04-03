
#define shaderName photoshop_blend_modes

#include "Common.h" 

//Darken
static float3 darken (float3 target, float3 blend){
    
 return min (target, blend);   
}

//Multiply
static float3 multiply (float3 target, float3 blend){
    return target*blend;
}

//Color Burn
static float3 colorBurn (float3 target, float3 blend){
    return 1.0 - (1.0 - target)/ blend;
}

//Linear Burn
static float3 linearBurn (float3 target, float3 blend){
    return target + blend - 1.0;
}

//Lighten
static float3 lighten (float3 target, float3 blend){
    return max (target, blend);
}

//Screen
static float3 screen (float3 target, float3 blend){
    return 1.0 - (1.0 - target) * (1.0 - blend);
}

//Color Dodge
static float3 colorDodge (float3 target, float3 blend){
    return target / (1.0 - blend);
}

//Linear Dodge
static float3 linearDodge (float3 target, float3 blend){
    return target + blend;
}

//Overlay
static float3 overlay (float3 target, float3 blend){
    float3 temp;
    temp.x = (target.x > 0.5) ? (1.0-(1.0-2.0*(target.x-0.5))*(1.0-blend.x)) : (2.0*target.x)*blend.x;
    temp.y = (target.y > 0.5) ? (1.0-(1.0-2.0*(target.y-0.5))*(1.0-blend.y)) : (2.0*target.y)*blend.y;
    temp.z = (target.z > 0.5) ? (1.0-(1.0-2.0*(target.z-0.5))*(1.0-blend.z)) : (2.0*target.z)*blend.z;
    return temp;
}

//Soft Light
static float3 softLight (float3 target, float3 blend){
 float3 temp;
    temp.x = (blend.x > 0.5) ? (1.0-(1.0-target.x)*(1.0-(blend.x-0.5))) : (target.x * (blend.x + 0.5));
    temp.y = (blend.y > 0.5) ? (1.0-(1.0-target.y)*(1.0-(blend.y-0.5))) : (target.y * (blend.y + 0.5));
    temp.z = (blend.z > 0.5) ? (1.0-(1.0-target.z)*(1.0-(blend.z-0.5))) : (target.z * (blend.z + 0.5));
    return temp;   
}

//Hard Light
static float3 hardLight (float3 target, float3 blend){
    float3 temp;
    temp.x = (blend.x > 0.5) ? (1.0-(1.0-target.x)*(1.0-2.0*(blend.x-0.5))) : (target.x * (2.0*blend.x));
    temp.y = (blend.y > 0.5) ? (1.0-(1.0-target.y)*(1.0-2.0*(blend.y-0.5))) : (target.y * (2.0*blend.y));
    temp.z = (blend.z > 0.5) ? (1.0-(1.0-target.z)*(1.0-2.0*(blend.z-0.5))) : (target.z * (2.0*blend.z));
    return temp;
}

//Vivid Light
static float3 vividLight (float3 target, float3 blend){
     float3 temp;
    temp.x = (blend.x > 0.5) ? (1.0-(1.0-target.x)/(2.0*(blend.x-0.5))) : (target.x / (1.0-2.0*blend.x));
    temp.y = (blend.y > 0.5) ? (1.0-(1.0-target.y)/(2.0*(blend.y-0.5))) : (target.y / (1.0-2.0*blend.y));
    temp.z = (blend.z > 0.5) ? (1.0-(1.0-target.z)/(2.0*(blend.z-0.5))) : (target.z / (1.0-2.0*blend.z));
    return temp;
}

//Linear Light
static float3 linearLight (float3 target, float3 blend){
    float3 temp;
    temp.x = (blend.x > 0.5) ? (target.x)+(2.0*(blend.x-0.5)) : (target.x +(2.0*blend.x-1.0));
    temp.y = (blend.y > 0.5) ? (target.y)+(2.0*(blend.y-0.5)) : (target.y +(2.0*blend.y-1.0));
    temp.z = (blend.z > 0.5) ? (target.z)+(2.0*(blend.z-0.5)) : (target.z +(2.0*blend.z-1.0));
    return temp;
}

//Pin Light
static float3 pinLight (float3 target, float3 blend){
     float3 temp;
    temp.x = (blend.x > 0.5) ? (max (target.x, 2.0*(blend.x-0.5))) : (min(target.x, 2.0*blend.x));
    temp.y = (blend.y > 0.5) ? (max (target.y, 2.0*(blend.y-0.5))) : (min(target.y, 2.0*blend.y));
    temp.z = (blend.z > 0.5) ? (max (target.z, 2.0*(blend.z-0.5))) : (min(target.z, 2.0*blend.z));
    return temp;
}

//Difference
static float3 difference (float3 target, float3 blend){
    return abs (target - blend);
    
}
//Exclusion
static float3 exclusion (float3 target, float3 blend){
    return 0.5 - 2.0*(target-0.5)*(blend-0.5);
    
}

//Subtract (thanks to Brandondorf9999)
static float3 subtract (float3 target, float3 blend){
    return target - blend;
}

//Divide (thanks to Brandondorf9999)
static float3 dividex (float3 target, float3 blend){
 return target/blend;   
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
	float2 uv = textureCoord;
	
	//upper texture
	float3 upperTexture = tex0.sample(iChannel0, uv).xyz;
	
	//lower texture
	float3 lowerTexture = tex1.sample(iChannel0, uv).xyz;
    
    int time = int (mod (uni.iTime, 18.0));
    
    float3 finalImage = float3(0.0);
    if (time==0) finalImage =  darken ( upperTexture,  lowerTexture	);
    else if (time==1) finalImage = multiply ( upperTexture,  lowerTexture);
    else if (time==2) finalImage =colorBurn ( upperTexture,  lowerTexture);
    else if (time==3) finalImage =linearBurn ( upperTexture,  lowerTexture);
    else if (time==4) finalImage =lighten ( upperTexture,  lowerTexture);
    else if (time==5) finalImage =screen ( upperTexture,  lowerTexture);
    else if (time==6) finalImage =colorDodge ( upperTexture,  lowerTexture);
    else if (time==7) finalImage =linearDodge (upperTexture,  lowerTexture);
    else if (time==8) finalImage =overlay ( upperTexture,  lowerTexture);
    else if (time==9) finalImage =softLight ( upperTexture,  lowerTexture);
    else if (time==10) finalImage =hardLight ( upperTexture,  lowerTexture);
    else if (time==11) finalImage =vividLight ( upperTexture,  lowerTexture);
    else if (time==12) finalImage =linearLight ( upperTexture,  lowerTexture);
    else if (time==13) finalImage =pinLight ( upperTexture,  lowerTexture);
    else if (time==14) finalImage =difference ( upperTexture,  lowerTexture);
    else if (time==15) finalImage =exclusion (upperTexture, lowerTexture);
        else if (time==16) finalImage = subtract(upperTexture, lowerTexture);
            else if (time== 17) finalImage = dividex(upperTexture, lowerTexture);
    
    //set the color
    return float4(finalImage, 1.0);
}

