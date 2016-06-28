// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file SpeedTree.cginc
/// @brief SpeedTree standard material properties.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_SPEED_TREE_CGINC
#define A_FEATURES_SPEED_TREE_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef GEOM_TYPE_BRANCH_DETAIL
    sampler2D _DetailTex;

    #ifdef EFFECT_BUMP
        sampler2D _DetailNormalMap;
    #endif
#endif

#ifdef EFFECT_HUE_VARIATION
    half4 _HueVariation;
#endif

/// Applies the SpeedTree feature to the given material data.
/// @param[in,out] s Material surface data.
void aSpeedTree(
    inout ASurface s) 
{
    half4 base = aSampleBase(s);

    s.baseColor = base.rgb;
    s.opacity = _Color.a * base.a;
    aCutout(s);

    s.ambientOcclusion = s.vertexColor.r;

#ifdef EFFECT_BUMP
    s.normalTangent = aSampleBump(s);
#endif
#ifdef GEOM_TYPE_BRANCH_DETAIL
    half4 detailColor = tex2D(_DetailTex, s.uv01.zw);
    half weight = s.vertexColor.g < 2.0f ? saturate(s.vertexColor.g) : detailColor.a;
    
    s.baseColor = lerp(s.baseColor, detailColor.rgb, weight);
    
    #ifdef EFFECT_BUMP
        half3 detailNormals = UnpackNormal(tex2D(_DetailNormalMap, s.uv01.zw));
        s.normalTangent = lerp(s.normalTangent, BlendNormals(s.normalTangent, detailNormals), weight);
    #endif
#endif
#ifdef EFFECT_HUE_VARIATION
    half3 shiftedColor = lerp(s.baseColor, _HueVariation.rgb, s.vertexColor.b);
    half maxBase = max(s.baseColor.r, max(s.baseColor.g, s.baseColor.b));
    half newMaxBase = max(shiftedColor.r, max(shiftedColor.g, shiftedColor.b));

    maxBase /= newMaxBase;
    maxBase = maxBase * 0.5f + 0.5f;
    // preserve vibrance
    shiftedColor.rgb *= maxBase;
    s.baseColor.rgb = saturate(shiftedColor);
#endif

    s.baseColor *= _Color.rgb;
} 

#endif // A_FEATURES_SPEED_TREE_CGINC
