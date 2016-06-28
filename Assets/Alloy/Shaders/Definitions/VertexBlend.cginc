// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file VertexBlend4Splat.cginc
/// @brief Vertex Blend 4Splat shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_VERTEX_BLEND_4SPLAT_CGINC
#define A_DEFINITIONS_VERTEX_BLEND_4SPLAT_CGINC

#define A_SPECULAR_TINT_ON
#define A_VERTEX_COLOR_BLEND_WEIGHTS
#define A_DETAIL_MASK_OFF

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Splat.cginc"

half _TriplanarBlendSharpness;

half3 _Splat0Tint;
A_SAMPLER2D(_Splat0);
sampler2D _Normal0;
half _Metallic0;
half _SplatSpecularity0;
half _SplatSpecularTint0;
half _SplatRoughness0;

half3 _Splat1Tint;
A_SAMPLER2D(_Splat1);
sampler2D _Normal1;
half _Metallic1;
half _SplatSpecularity1;
half _SplatSpecularTint1;
half _SplatRoughness1;

half3 _Splat2Tint;
A_SAMPLER2D(_Splat2);
sampler2D _Normal2;
half _Metallic2;
half _SplatSpecularity2;
half _SplatSpecularTint2;
half _SplatRoughness2;

half3 _Splat3Tint;
A_SAMPLER2D(_Splat3);
sampler2D _Normal3;
half _Metallic3;
half _SplatSpecularity3;
half _SplatSpecularTint3;
half _SplatRoughness3;

void aSurface(
    inout ASurface s)
{	
    half4 splatControl = s.vertexColor;
    
    splatControl /= (dot(splatControl, half4(1.0h, 1.0h, 1.0h, 1.0h)) + A_EPSILON);

    //float2 splat0Uv = A_TRANSFORM_UV_SCROLL(s, _Splat0);
    ASplatContext sc = aCreateSplatContext(s, _TriplanarBlendSharpness, 1.0f);
    ASplat sp0 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat0), _Normal0, _Splat0Tint, _Metallic0, _SplatSpecularity0, _SplatSpecularTint0, _SplatRoughness0);
    ASplat sp1 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat1), _Normal1, _Splat1Tint, _Metallic1, _SplatSpecularity1, _SplatSpecularTint1, _SplatRoughness1);
    ASplat sp2 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat2), _Normal2, _Splat2Tint, _Metallic2, _SplatSpecularity2, _SplatSpecularTint2, _SplatRoughness2);
    ASplat sp3 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat3), _Normal3, _Splat3Tint, _Metallic3, _SplatSpecularity3, _SplatSpecularTint3, _SplatRoughness3);
    
    aApplyTerrainSplats(s, splatControl, sp0, sp1, sp2, sp3);
    aDetail(s);
    aUpdateNormalData(s);
}

#endif // A_DEFINITIONS_VERTEX_BLEND_4SPLAT_CGINC
