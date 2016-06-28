// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file SecondaryTextures.cginc
/// @brief Secondary set of textures.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_SECONDARY_TEXTURES_CGINC
#define A_FEATURES_SECONDARY_TEXTURES_CGINC

#ifdef _RIM2_ON
    #ifndef A_VIEW_VECTOR_TANGENT_ON
        #define A_VIEW_VECTOR_TANGENT_ON
    #endif
#endif

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef A_SECONDARY_TEXTURES_ON
    /// The secondary tint color.
    /// Expects a linear LDR color with alpha.
    half4 _Color2;
    
    /// The secondary color map.
    /// Expects an RGB(A) map with sRGB sampling.
    A_SAMPLER2D(_MainTex2);

    #ifndef _SECONDARYROUGHNESSSOURCE_BASECOLORALPHA
        /// The secondary packed material map.
        /// Expects an RGBA data map.
        sampler2D _MaterialMap2;
    #endif

    /// The secondary normal map.
    /// Expects a compressed normal map.
    sampler2D _BumpMap2;
    
    /// Toggles tinting the secondary color by the vertex color.
    /// Expects values in the range [0,1].
    half _BaseColorVertexTint2;

    /// The secondary metallic scale.
    /// Expects values in the range [0,1].
    half _Metallic2;

    /// The secondary specularity scale.
    /// Expects values in the range [0,1].
    half _Specularity2;
    
    /// The secondary roughness scale.
    /// Expects values in the range [0,1].
    half _Roughness2;
    
    /// Ambient Occlusion strength.
    /// Expects values in the range [0,1].
    half _Occlusion2;

    /// Normal map XY scale.
    half _BumpScale2;
#endif

/// Applies the Secondary Textures feature to the given material data.
/// @param[in,out] s Material surface data.
void aSecondaryTextures(
    inout ASurface s)
{
#ifdef A_SECONDARY_TEXTURES_ON
    float2 baseUv2 = A_TRANSFORM_UV_SCROLL(s, _MainTex2);
    half mask = s.mask;
    half4 material2 = half4(_Metallic2, 1.0h, _Specularity2, _Roughness2);
    half4 base2 = _Color2 * tex2D(_MainTex2, baseUv2);

    base2.rgb *= aLerpWhiteTo(s.vertexColor.rgb, _BaseColorVertexTint2);
    
    #ifdef _SECONDARYROUGHNESSSOURCE_BASECOLORALPHA
        material2.w *= base2.a;
        base2.a = 1.0h;
    #else
        #ifndef A_SECONDARY_TEXTURES_ALPHA_BLEND_OFF
            mask *= base2.a;
            base2.a = 1.0h;
        #endif

        material2 *= tex2D(_MaterialMap2, baseUv2);
        material2.y = aLerpOneTo(GammaToLinearSpace(material2.yyy).x, _Occlusion2);
    #endif

    s.baseColor = lerp(s.baseColor, base2.rgb, mask);
    s.opacity = lerp(s.opacity, base2.a, mask);

    s.metallic = lerp(s.metallic, material2.x, mask);
    s.ambientOcclusion = lerp(s.ambientOcclusion, material2.y, mask);
    s.specularity = lerp(s.specularity, material2.z, mask);
    s.roughness = lerp(s.roughness, material2.w, mask);

    s.emission *= (1.0h - mask);

    half3 normal2 = UnpackScaleNormal(tex2D(_BumpMap2, baseUv2), _BumpScale2);
    s.normalTangent = normalize(lerp(s.normalTangent, normal2, mask)); 

    // NOTE: These are applied in here so we can use baseUv2.
    float2 baseUv = s.baseUv;
    s.baseUv = baseUv2;
    aEmission2(s);

    #ifdef _RIM2_ON
        s.NdotV = aDotClamp(s.normalTangent, s.viewDirTangent);
        aRim2(s);
    #endif
    
    s.baseUv = baseUv;
#endif
}

#endif // A_FEATURES_SECONDARY_TEXTURES_CGINC
