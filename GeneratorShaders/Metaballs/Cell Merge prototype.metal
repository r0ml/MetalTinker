
#define shaderName cell_merge_prototype

#include "Common.h" 


#define sin60 0.86602540378

#define clicksize 1.0

constant const float3 color_bg = float3(0.0,0.0,0.0);
constant const float3 color_inner = float3(1.0,1.0,0.0);
constant const float3 color_outer = float3(0.5,0.8,0.3);

static float getVolume(float2 localPos, float radius)
{
    localPos = abs(localPos);
    
    float2 maxPos = localPos + float2(0.5);
    
    float rr2 = radius * radius;
    
    if( dot(maxPos, maxPos) <= rr2)
    {
        return 1.0;
    }
    
    float2 minPos = localPos - float2(0.5);
    if( dot(minPos, minPos) >= rr2)
    {
        return 0.0;
    }
    
    float2 pA, pB;
    // pA
    if( sqrt(radius * radius - minPos.x * minPos.x) > maxPos.y)
    {
        pA = float2(sqrt(rr2 - maxPos.y * maxPos.y) , maxPos.y);
    }
    else
    {
        pA = float2(minPos.x, sqrt(rr2 - minPos.x * minPos.x));
    }
    //pB
    if( sqrt(radius * radius - minPos.y * minPos.y) > maxPos.x)
    {
        pB = float2( maxPos.x, sqrt(rr2 - maxPos.x * maxPos.x));
    }
    else
    {
        pB = float2( sqrt(rr2 - minPos.y * minPos.y), minPos.y);
    }
    
    float2 block = abs(pB-pA);
    float areaTri = (block.x * block.y) / 2.0;
    
    float areaBoxWidth = min(pA.x, pB.x) - minPos.x;
    float areaBoxHeight = min(pA.y, pB.y) - minPos.y;
    
    float areaBoxOverlap = areaBoxWidth * areaBoxHeight;
    
    float areaTotal = areaTri + areaBoxWidth + areaBoxHeight - areaBoxOverlap ;
    
    return areaTotal;
}

static float2 getCellVolume(float2 winCoord, float4 cell)
{
    float2 volume = float2(0.0);
    volume.x = getVolume(cell.xy - winCoord, cell.z);
    if( volume.x == 0.0 )
    {
        volume.y = getVolume(cell.xy - winCoord, cell.w);
    }
    else
    {
        volume.y = 1.0 - volume.x;
    }
    return volume;
}

static float2 getCellVolumeMerge(float2 winCoord, float4 cell1, float4 cell2)
{
    float2 circleSize = (cell1.zw + cell2.zw) / 2.0; // average size 
    
    float dis = distance(cell1.xy, cell2.xy);
    
    circleSize /= (dis * 1.3 / circleSize);
    
    
    float2 forward = normalize(cell2.xy-cell1.xy);
    float2 right = float2(forward.y, -forward.x);
    
    float2 length1 = cell1.zw + circleSize;
    float2 length2 = cell2.zw + circleSize;
    
    float2 volume = float2(0.0);
    
    if( dis < length1.x + length2.x )// test inner
    {
        float L1 = length1.x;
        float L2 = length2.x;
        
        float cosA = (dis*dis + L1*L1 - L2*L2) / (2.0 * dis * L1);
        
        float Lf = cosA * L1;
        float Ls = sqrt(L1*L1 - Lf*Lf);
        
        if(Ls > circleSize.x)
        {
            float2 pointRight = cell1.xy + forward * Lf + right * Ls;
            float2 pointLeft = cell1.xy + forward * Lf - right * Ls;

            float2 checkPR1 = normalize(cell1.xy - pointRight);
            checkPR1 = float2(checkPR1.y, -checkPR1.x); // rotate CW
            float2 checkPR2 = normalize(cell2.xy - pointRight);
            checkPR2 = float2(-checkPR2.y, checkPR2.x); // rotate CCW

            float2 checkPL1 = normalize(cell1.xy - pointLeft);
            checkPL1 = float2(-checkPL1.y, checkPL1.x); // rotate CCW
            float2 checkPL2 = normalize(cell2.xy - pointLeft);
            checkPL2 = float2(checkPL2.y, -checkPL2.x); // rotate CW

            float2 fromR = winCoord - pointRight;
            float2 fromL = winCoord - pointLeft;

            if(dot(checkPR1,fromR) > 0.0 && dot(checkPR2, fromR) > 0.0 
                && dot(checkPL1,fromL) > 0.0 && dot(checkPL2, fromL) > 0.0)
            {
                volume.x = 1.0 - getVolume(fromR, circleSize.x) - getVolume(fromL, circleSize.x);
            }
        }
    }
    
    if( dis < length1.y + length2.y )// outer
    {
        float L1 = length1.y;
        float L2 = length2.y;
        
        float cosA = (dis*dis + L1*L1 - L2*L2) / (2.0 * dis * L1);
        
        float Lf = cosA * L1;
        float Ls = sqrt(L1*L1 - Lf*Lf);
        
        if(Ls > circleSize.y)
        {
            float2 pointRight = cell1.xy + forward * Lf + right * Ls;
            float2 pointLeft = cell1.xy + forward * Lf - right * Ls;

            float2 checkPR1 = normalize(cell1.xy - pointRight);
            checkPR1 = float2(checkPR1.y, -checkPR1.x); // rotate CW
            float2 checkPR2 = normalize(cell2.xy - pointRight);
            checkPR2 = float2(-checkPR2.y, checkPR2.x); // rotate CCW

            float2 checkPL1 = normalize(cell1.xy - pointLeft);
            checkPL1 = float2(-checkPL1.y, checkPL1.x); // rotate CCW
            float2 checkPL2 = normalize(cell2.xy - pointLeft);
            checkPL2 = float2(checkPL2.y, -checkPL2.x); // rotate CW

            float2 fromR = winCoord - pointRight;
            float2 fromL = winCoord - pointLeft;

            if(dot(checkPR1,fromR) > 0.0 && dot(checkPR2, fromR) > 0.0 
                && dot(checkPL1,fromL) > 0.0 && dot(checkPL2, fromL) > 0.0)
            {
                volume.y = 1.0 - getVolume(fromR, circleSize.y) - getVolume(fromL, circleSize.y);
            }
        }
    }
    
    
    return volume;
}

static float3 volumeToColor(float2 volume)
{
    if( volume.x != 0.0 )
    {
        return mix(color_outer, color_inner, min(1.0,volume.x));
    }
    return mix(color_bg, color_outer, min(1.0,volume.y));
}

fragmentFunc(constant float2& mouse) {
    float2 cellSize = float2( 40.0, 60.0);
    
    float s60r = sin60 * cellSize.y;
    
  float2 center = 2 / scn_frame.inverseResolution;

    float4 cell1 = float4(center + float2(cellSize.y,-s60r), cellSize);
    float4 cell2 = float4(center + float2(-cellSize.y,-s60r), cellSize);
    float4 cell3 = float4(center + float2(sin(scn_frame.time*0.25)*150.0, s60r), cellSize);
    
    float4 cell4 = float4(mouse /scn_frame.inverseResolution, cellSize * clicksize);
    
    
    float2 volume = float2(0.0); // x = inner, y = outer
    
    volume += getCellVolume(thisVertex.where.xy, cell1);
    volume += getCellVolume(thisVertex.where.xy, cell2);
    volume += getCellVolume(thisVertex.where.xy, cell3);
    volume += getCellVolume(thisVertex.where.xy, cell4);
    
    volume += getCellVolumeMerge(thisVertex.where.xy, cell1, cell4);
    volume += getCellVolumeMerge(thisVertex.where.xy, cell2, cell4);
    volume += getCellVolumeMerge(thisVertex.where.xy, cell3, cell4);
    volume += getCellVolumeMerge(thisVertex.where.xy, cell1, cell2);
    volume += getCellVolumeMerge(thisVertex.where.xy, cell2, cell3);
    volume += getCellVolumeMerge(thisVertex.where.xy, cell3, cell1);
    
    return float4(volumeToColor(volume),1.0);
}

 
