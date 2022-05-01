/** 
Author: Shane
I tend to call them fish scale tiles, but I've heard them referred to as Japanese wave patterns, European tiles, etc. Either way, it's just an excuse to play around with 2D polar coordinates.

	Japanese Wave Pattern
	---------------------

	I tend to call them fish scale tiles, but I've heard them referred to as Japanese wave 
	patterns, European tiles, etc. Either way, it's just an excuse to play around with 2D 
	polar coordinates.

	This particular design is based on something I came across on the net years ago. I'm 
	not sure who originally came up with it, but I see it frequently in various forms all 
	over the net. I have a feeling that the originals were hand drawn, because I don't 
	think anyone would ever get bored enough to code one... :)

	Conceptually, there's nothing difficult here, but the routines are a little fiddly. In 
	essence, the texture is constructed from a series of fan-like shapes made up of 
	combinations of strategically placed circles. Decorating the tiles involves a few steps, 
	due to the intricate details. However, it's essentially nothing more than a few lines 
	and shapes rendered on a polar grid.

	Getting finely detailed images to look right on everyone's system is impossible. I find 
	the biggest problem is the large range in PPIs these days. What looks right on my 
	system might not look that great on someone elses.

	I coded this using the 800x450 canvas on a 17 inch laptop with 1920x1080 resolution, so 
	the resulting image physically looks the size of Samsung phone in side view. However, 
	it's not uncommon for people to have systems with PPIs way in excess of that these days, 
	which would result in a much smaller image, and thus, squashed details. Unfortunately, 
	it's not possibe to control that.

	In order to show the repeat texture qualities, I've opted for scales that look the same 
	size at different resolutions. That may or may not have been the best choice.

    There's a compile option to distinguish between alternating scale layers and another 
	option to turn off the highlights, just in case a rippling, hardened scale is messing 
	with your sense of physical correctness. It disturbs mine a bit. :)

	Other examples:

	// I deliberately refrained from looking at Kuvkar's rendition in the hope that I could 
    // bring something new to the table. I didn't. :D
	European Cobblestone Tiles - kuvkar
	https://www.shadertoy.com/view/ldyXz1

	// Awesome usage of fish scales would be putting it mildly. :)
	Kelp Forest - BigWIngs
	https://www.shadertoy.com/view/llcSz8

	// Fabrices take on it. I might look into it more closely.
	Hexagonal Tiling 5 - FabriceNeyret2
    https://www.shadertoy.com/view/4dKXz3


*/


#define shaderName japanese_wave_pattern

#include "Common.h" 

struct InputBuffer { };

initialize() {}


 



// Cheap bump highlights.
constant const bool SHOW_HIGHLIGHTS = true;

// Distinguishes between the two layers by changing the color of one.
constant const bool SHOW_ALTERNATE_LAYERS = false;
   

// Fabrices consice, 2D rotation formula.
static float2x2 r2(float th){ float2 a = sin(float2(1.5707963, 0) + th); return float2x2(a.x, a.y, -a.y, a.x); }



// Decorating each scale. For all intents and purposes, this is a demonstration of converting
// an N by N square grid to N by N disc-like polar cells and drawing some things in them.
// The code looks more involved than it really is, due to the coloring, decision making, etc. 
static float3 scaleDec(float2 p, float layerID, thread float & bumpValue , const float time){

    // Square grid partioning for the scales. This will be further partitioned into a polar
    // grid to draw some details.
    p = mod(p, float2(.9, .5)) - float2(.9, .5)/2.;


    
    // Mover the center of the disc to the top of the cell. In fact, we've moved it slightly 
    // higher to allow for the thicker fan border.
    p -= float2(-.05, -.28);
    

    
    // Pinching the design together along X to match the fact that we're drawing circles slightly
    // squashed along X... Technically ellipses.
    // We're also multiply by a scalar factor or 14. This breaks each scale into a 14x14 grid, 
    // which we'll convert to polar coordinates. See the radius (r) and angle (a) lines below.
    p *= 14./float2(.95, 1); 
    
    float r = length(p); // Radius. The radial part of the polar coordinate.
    float patID = step(.5, fract(r/2.)); // Pattern ID. Either lines or the sinusoidal design.
     
    
    // Rotate: I've given the layer IDs values of one and negative-one, in order to spin the
    // discs in opposing directions... I figured it might look more interesting. Commenting it
    // out stops the rotation.
    p *= r2(-time/12.*layerID);
    //p *= r2(-uni.iTime/48.*(floor(r) + 4.)*spin); // Rotate sections at differt rates.
    //if(patID>.5) p *= r2(-uni.iTime/12.*spin);  // Only rotate half the sections.
    
    
    // Controls the amount of vertical lines in each polar segment. Just to make things difficult,
    // I wanted a higher density of lines and squiggles as we moved down the scale.
    float vLineNum = floor(r)*12. + 16.;    
    if(patID>.5)  vLineNum /= 2.; // Lower the frequency where rendering the squiggly bits.
    
    
    // Angle of the pixel in the grid with respect to the center.
    float a = atan2(p.y, p.x);
    // Partioning the angles into a number of segments.
    float ia = floor(a*vLineNum/TAU);
    ia = (ia + .5)/vLineNum*TAU;
    
    // Rotating by the segment angle above.
    p *= r2(ia);
    p.x = fract(p.x) - .5; 
    
	// The vertical lines.
    float vLine = abs(p.y) - .05;  
    vLine = smoothstep(0., fwidth(vLine), vLine)*.75 + .25;//step(0., d);////clamp(fwidth(vLine), 0., .1)*2.
    if(patID>.5) vLine = 1.; // No vertical lines every second segment.
    
    // Horizontal partitioning lines.
    float hLine = abs(fract(r + .5) - .5) - .05;
    hLine = smoothstep(0., fwidth(hLine), hLine);
 
    // Scale border - Smooth (trial and error) version of: if(r>7.15) hLine1 *= .05;
    hLine *= .05 + smoothstep(0., fwidth(7.2 - r), 7.2-r)*.95; 
    
    // Every second partition, draw a sinusoidal pattern.
    if(patID>.5){
        
        // Line, centered in the partition, perturbed sinusoidally.
        float wave = sin(a*vLineNum/2.)*.2;
        float hLine2 = abs(fract(r + wave) - .5) - .04;
        hLine2 = smoothstep(0., fwidth(hLine2), hLine2);
        // Place some dots in amongst the sinusoid.
        float dots = length(p - float2(wave*.5, 0)) - .07;
        dots = smoothstep(0., fwidth(dots), dots);
        hLine2 = min(hLine2, dots);
        hLine2 = hLine2*.8 + .2;
        
        hLine = min(hLine, hLine2);
    }
    
    
    // Combining the horizontal line patterns and the vertical lines.   
    float3 col = float3(1)*min(vLine, hLine);
    
	// Color up every second partition according to object ID. I did this out of 
    // sheer boredom. :)
    if(patID<.5) {        
        
        if (layerID > 0.) col *= float3(.7, .9, 1.3);
        else col *= float3(.8, 1.2, 1.4);
    }
    
    // Apply some color, dependent on segment number.
    float3 gradCol = pow(float3(1.5, 1, 1)*max(1. - floor(r)/7.*.7, 0.), float3(1, 2, 10)); 
    //float3 gradCol = pow(float3(1.5, 1, 1)*max(1. - (r)/7.*.7, 0.), float3(1, 2, 10)); 
    //float3 gradCol = pow(float3(1.5, 1, 1)*max(1. - (r)/7.*.7, 0.), float3(1, 3, 16)); 

    // Very simple bump value. It's a global variable, separate to the coloring. It's
    // a bit of hack added after the fact, but it works.
    //bumpFunc = cos(r*6.283)*.5 + .5;
    bumpValue = 1. - saturate(-cos(r*TAU)*2. + 1.5);
   
    
    // Return the final color.
    return col*(min(gradCol, 1.)*.98 + .02);
    
    
    
}

// Basically, three circular shapes combined in such a way as to create a fan. The result 
// is a grid "half" filled with fan shapes. A second layer - offset appropriately - is 
// required to fill in the entire space to create the overall scale texture.
//
// By the way, the procedure below is pretty simple, but a little difficult to describe. 
// Isolating the function and running it by itself is the best way to grasp it.
static float scalesMask(float2 p){

    
    const float fwScale = 3.; // "fwidth" smoothing scale. Controls border blurriness to a degree.
 
    // Repeat space: Breaking it up into .9 by .5 squares... just to be difficult. :)
    // I wanted the scales to overlap slightly closer together, which meant bringing the centers
    // closer together. This meant offsetting everything... You have my apologies. :)
    p = mod(p, float2(.9, .5)) - float2(.9, .5)/2.;
 
    
    // Draw a circle, centered at the top of the .9 by .5 rectangle.
    float c = length(p +  float2(.0, .25)); 
    c = smoothstep(0.,  min(fwidth(c), .01)*fwScale, c - .5);

    float mask = c;

    // Chopped off two partial circles at the top left and top right. They're positioned in such
    // a way to create a fan shape.
    //
    // The "sign" business is just a repetitive trick to take care of two quadrants at once.
    // "sign(p.x)" has the effect of an "if" statement.
    c = length(p - float2(sign(p.x)*.9, -1.)*.5);
    
    
    // Combine the three circular shapes to create the fan.
    return max(mask, smoothstep(0., min(fwidth(c), .01)*fwScale, .5 - c));
    
}

// The decrotated scale tiles. Render one set of decorated fans, combine them with the
// other set, then add some highlighting and postprocessing.
static float3 scaleTile(float2 p, thread float& bumpValue, const float time){
    
    // Contorting the scale a bit to add to the hand-drawn look.
    float2 scale = float2(3, -2.);
    
    // One set of scale tiles, which take up half the space.
    float sm = scalesMask(p*scale); // Mask.
  float3 col = sm*scaleDec(p*scale + float2(-.5, -.25), 1., bumpValue, time); // Decoration.
    float bf2 = bumpValue*sm;
    
    // The other set of scale tiles.
    float sm2 = scalesMask(p*scale + float2(-.45, -.75)); // Mask.
    float3 col2 = sm2*scaleDec(p*scale + float2(-.5, -.75) + float2(-.45, -.25), -1., bumpValue, time); // Decoration.
    
    
  if ( SHOW_ALTERNATE_LAYERS ) {
    // A simple way to distinguish between the two layers.
    col2 = col2*.7 + col2.yxz*.3;
  }
    
    // Add some highlighting.
    bumpValue = max(bf2, bumpValue*sm2);
    col = max(col, col2);
    
    // Toning the color down a bit. This was a last minute thing.
    return col*.8 + col.zxy*.2;
    
}

fragmentFn() {

    // A cheap hack to store a bump value.
    float bumpValue;

    // Screen coordinates. Feel free to tweak it, if you want.
	float2 uv = worldCoordAspectAdjusted / 2 ;

    // Perturbing - and shifting - the screen coordinates for a bit of a wavy effect. It
    // gives the texture a kind of hand-drawn feel.
    uv += sin(uv*PI*3. - sin(uv.yx*PI*6. + uni.iTime*.5))*.0075 + float2(0, .125);
 
    
    // Producing the scale tile.
  float3 col = scaleTile(uv, bumpValue, uni.iTime);
  if ( SHOW_HIGHLIGHTS ) {
    float bf = bumpValue; // Saving the bump value.
    
    // Taking a second nearby sample, in order to produce some cheap highlighting.
    float3 col2 = scaleTile(uv + .5/450., bumpValue, uni.iTime);// 450.;
    float bf2 = bumpValue;
    
    // Color-based, or texture based bump.
    float bump = max(grayscale(col2 - col), 0.)*4.;
    // Adding a cheap and nasty functional bump. It effectively adds some extra contour.
    bump += max(bf2 - bf, 0.)*2.;
    
    
    // Add the rough highlighting.
    col = col + float3(1, 1, 1.5)*(col*.9 + .1)*bump;
    //col = col*(float3(.5, .7, 1)*bump*8. + 1.);
  }
    
    // Rought gamma correction.
    return float4(sqrt(saturate(col)), 1);
}


