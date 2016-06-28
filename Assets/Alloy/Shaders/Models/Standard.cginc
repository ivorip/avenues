// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Standard.cginc
/// @brief Standard model inputs and outputs.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_MODELS_STANDARD_CGINC
#define A_MODELS_STANDARD_CGINC

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
    UNITY_APPLY_FOG(s.fogCoord, color);
}

void aFinalGbuffer(
    ASurface s,
    inout half4 diffuse,
    inout half4 specSmoothness,
    inout half4 normal,
    inout half4 emission)
{

}

#endif // A_MODELS_STANDARD_CGINC
