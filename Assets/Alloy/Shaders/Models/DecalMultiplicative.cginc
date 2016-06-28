// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file DecalMultiplicative.cginc
/// @brief Multiplicative decal inputs and outputs.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_MODELS_DECAL_MULTIPLICATIVE_CGINC
#define A_MODELS_DECAL_MULTIPLICATIVE_CGINC

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
    color = half4(s.baseColor, 1.0h);

    // Fog to white to allow underlying surface fog to bleed through.
    UNITY_APPLY_FOG_COLOR(s.fogCoord, color, half4(1.0h, 1.0h, 1.0h, 1.0h));
}

void aFinalGbuffer(
    ASurface s,
    inout half4 diffuse,
    inout half4 specSmoothness,
    inout half4 normal,
    inout half4 emission)
{
    half4 color = half4(s.baseColor, 1.0h);

    diffuse = color;
    specSmoothness = color;
    normal = half4(1.0h, 1.0h, 1.0h, 1.0h);
    emission = color;
}

#endif // A_MODELS_DECAL_MULTIPLICATIVE_CGINC
