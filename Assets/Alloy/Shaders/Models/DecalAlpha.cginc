// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file DecalAlpha.cginc
/// @brief Alpha decal inputs and outputs.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_MODELS_DECAL_ALPHA_CGINC
#define A_MODELS_DECAL_ALPHA_CGINC

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
    // Deferred alpha decal two-pass solution.
    // cf http://forum.unity3d.com/threads/how-do-i-write-a-normal-decal-shader-using-a-newly-added-unity-5-2-finalgbuffer-modifier.356644/page-2
#ifdef A_DECAL_ALPHA_FIRSTPASS
    diffuse.a = s.opacity;
    specSmoothness.a = s.opacity;
    normal.a = s.opacity;
    emission.a = s.opacity;
#else
    diffuse.a *= s.opacity;
    specSmoothness.a *= s.opacity;
    normal.a *= s.opacity;
    emission.a *= s.opacity;
#endif
}

#endif // A_MODELS_DECAL_ALPHA_CGINC
