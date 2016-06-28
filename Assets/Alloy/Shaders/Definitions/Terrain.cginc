// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Terrain.cginc
/// @brief Terrain surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_TERRAIN_CGINC
#define A_DEFINITIONS_TERRAIN_CGINC

#ifndef A_TERRAIN_DISTANT
    #define A_VIEW_DEPTH_ON
#endif

#define A_VERTEX_COLOR_BLEND_WEIGHTS
#define A_SPECULAR_TINT_ON
#define A_DETAIL_MASK_OFF

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/Terrain.cginc"
#include "Assets/Alloy/Shaders/Framework/Splat.cginc"

#ifdef A_TERRAIN_DISTANT
    sampler2D _MetallicTex;
#else
    A_SAMPLER2D(_Control);
    half _TriplanarBlendSharpness;
    
    A_SAMPLER2D(_Splat0);
    sampler2D _Normal0;
    half _Metallic0;
    half _SplatSpecularity0;
    half _SplatSpecularTint0;

    A_SAMPLER2D(_Splat1);
    sampler2D _Normal1;
    half _Metallic1;
    half _SplatSpecularity1;
    half _SplatSpecularTint1;

    A_SAMPLER2D(_Splat2);
    sampler2D _Normal2;
    half _Metallic2;
    half _SplatSpecularity2;
    half _SplatSpecularTint2;

    A_SAMPLER2D(_Splat3);
    sampler2D _Normal3;
    half _Metallic3;
    half _SplatSpecularity3;
    half _SplatSpecularTint3;
    
    half _FadeDist;
    half _FadeRange;
#endif

half _DistantSpecularity;
half _DistantSpecularTint;
half _DistantRoughness;

void aSurface(
    inout ASurface s)
{
#ifdef A_TERRAIN_DISTANT
    half4 col = aSampleBase(s);
    
    s.baseColor = col.rgb;
    s.metallic = tex2D (_MetallicTex, s.baseUv).r;	
    s.specularity = _DistantSpecularity;
    s.specularTint = _DistantSpecularTint;
    s.roughness = col.a * _DistantRoughness;
    
    aDetail(s);
    aUpdateNormalData(s);
#else
    // Create a smooth blend between near and distant terrain to hide transition.
    // NOTE: Can't kill specular completely since we have to worry about deferred.
    // cf http://wiki.unity3d.com/index.php?title=AlphaClipsafe
    half fade = saturate((s.viewDepth - _FadeDist) / _FadeRange);
    half4 splatControl = tex2D(_Control, TRANSFORM_TEX(s.uv01.xy, _Control));
    half weight = dot(splatControl, half4(1.0h, 1.0h, 1.0h, 1.0h));
    
    #if !defined(SHADER_API_MOBILE) && defined(A_TERRAIN_SPLAT_ADDPASS)
        clip(weight - 0.0039 /*1/255*/);
    #endif

    splatControl /= (weight + A_EPSILON);

    // NOTE: 0.01 matches tiling of distant terrain combined maps.
    ASplatContext sc = aCreateSplatContext(s, _TriplanarBlendSharpness, 0.01f);
    half4 tint = 1.0h;
    half roughness = 1.0h;

    ASplat sp0 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat0), _Normal0, tint, _Metallic0, _SplatSpecularity0, _SplatSpecularTint0, roughness);
    ASplat sp1 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat1), _Normal1, tint, _Metallic1, _SplatSpecularity1, _SplatSpecularTint1, roughness);
    ASplat sp2 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat2), _Normal2, tint, _Metallic2, _SplatSpecularity2, _SplatSpecularTint2, roughness);
    ASplat sp3 = aCreateTerrainSplat(sc, A_SAMPLER_INPUT(_Splat3), _Normal3, tint, _Metallic3, _SplatSpecularity3, _SplatSpecularTint3, roughness);

    aApplyTerrainSplats(s, splatControl, sp0, sp1, sp2, sp3);
        
    #ifdef A_TERRAIN_NSPLAT
        s.specularity = _DistantSpecularity;
        s.specularTint = _DistantSpecularTint;
    #else
        s.specularity = lerp(s.specularity, _DistantSpecularity, fade);
        s.specularTint = lerp(s.specularTint, _DistantSpecularTint, fade);
    #endif

    s.roughness *= aLerpOneTo(_DistantRoughness, fade);
    s.normalTangent = normalize(lerp(s.normalTangent, A_FLAT_NORMAL, fade));

    aDetail(s);
    aUpdateNormalData(s);
    s.opacity = weight; // Last to avoid being overwritten.
#endif
}

#endif // A_DEFINITIONS_TERRAIN_CGINC
