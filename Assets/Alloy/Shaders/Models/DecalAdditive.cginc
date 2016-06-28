// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file DecalAdditive.cginc
/// @brief Additive decal inputs and outputs.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_MODELS_DECAL_ADDITIVE_CGINC
#define A_MODELS_DECAL_ADDITIVE_CGINC

#include "Assets/Alloy/Shaders/Framework/Model.cginc"

void aVertex(
    inout AVertex v)
{
#ifndef A_VERTEX_COLOR_BLEND_WEIGHTS
    v.color.rgb = GammaToLinearSpace(v.color.rgb);
#endif
}

void aFinalColor(
    ASurface s,
    inout half4 color)
{
    // Fog to black to allow underlying surface fog to bleed through.
    UNITY_APPLY_FOG_COLOR(s.fogCoord, color, half4(0.0h, 0.0h, 0.0h, 0.0h));
}

void aFinalGbuffer(
    ASurface s,
    inout half4 diffuse,
    inout half4 specSmoothness,
    inout half4 normal,
    inout half4 emission)
{
    diffuse = 0.0h;
    specSmoothness = 0.0h;
    normal = 0.0h;
    emission.w = 0.0h;
}

#endif // A_MODELS_DECAL_ADDITIVE_CGINC
