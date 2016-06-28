// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Terrain.cginc
/// @brief Terrain model inputs and outputs.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_MODELS_TERRAIN_CGINC
#define A_MODELS_TERRAIN_CGINC

#ifndef A_VERTEX_COLOR_BLEND_WEIGHTS
    #define A_VERTEX_COLOR_BLEND_WEIGHTS
#endif

#include "Assets/Alloy/Shaders/Framework/Model.cginc"

void aVertex(
    inout AVertex v)
{
#ifdef A_TANGENT_TO_WORLD_ON
    v.tangent.xyz = cross(v.normal, A_FLAT_NORMAL);
    v.tangent.w = -1.0f;
#endif
}

void aFinalColor(
    ASurface s,
    inout half4 color)
{
#ifdef A_TERRAIN_NSPLAT
    color *= s.opacity;

    #ifdef A_TERRAIN_SPLAT_ADDPASS
        UNITY_APPLY_FOG_COLOR(s.fogCoord, color, half4(0.0h, 0.0h, 0.0h, 0.0h));
    #else
        UNITY_APPLY_FOG(s.fogCoord, color);
    #endif
#endif
}

void aFinalGbuffer(
    ASurface s,
    inout half4 diffuse,
    inout half4 specSmoothness,
    inout half4 normal,
    inout half4 emission)
{
#ifdef A_TERRAIN_NSPLAT
    diffuse *= s.opacity;
    specSmoothness *= s.opacity;
    normal *= s.opacity;
    emission *= s.opacity;
#endif
}

#endif // A_MODELS_TERRAIN_CGINC
