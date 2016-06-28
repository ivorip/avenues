// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Detail.cginc
/// @brief Surface detail materials and normals.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_DETAIL_CGINC
#define A_FEATURES_DETAIL_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _DETAIL_ON	
    #ifndef A_DETAIL_MASK_OFF
        /// Mask that controls the detail influence on the base material.
        /// Expects an alpha data map.
        sampler2D _DetailMask;
    #endif

    /// Detail base color blending mode.
    /// Expects either 0 or 1.
    float _DetailMode;

    #ifndef A_DETAIL_COLOR_MAP_OFF
        /// Detail base color map.
        /// Expects an RGB map with sRGB sampling.
        A_SAMPLER2D(_DetailAlbedoMap);
    #endif
    
    #ifndef A_DETAIL_MATERIAL_MAP_OFF
        /// Detail ambient occlusion(G) and specular AA(A).
        /// Expects an RGBA data map.
        A_SAMPLER2D(_DetailMaterialMap);
    #endif
    
    #ifndef A_DETAIL_NORMAL_MAP_OFF
        /// Detail normal map.
        /// Expects a compressed normal map..
        A_SAMPLER2D(_DetailNormalMap);
    #endif

    /// Controls the detail influence on the base material.
    /// Expects values in the range [0,1].
    half _DetailWeight;

    /// Width of the area where details will appear, simulating micro-occlusion.
    /// Expects values in the range [0.01,n].
    half _DetailFalloff;
    
    /// Ambient Occlusion strength.
    /// Expects values in the range [0,1].
    half _DetailOcclusion;
    
    /// Normal map XY scale.
    half _DetailNormalMapScale;
#endif

/// Applies the Detail feature to the given material data.
/// @param[in,out] s Material surface data.
void aDetail(
    inout ASurface s) 
{
#ifdef _DETAIL_ON
    half mask = s.mask * _DetailWeight;
    
    #ifdef A_DETAIL_FALLOFF_ON
        mask *= pow(s.NdotV, _DetailFalloff);
    #endif

    #ifndef A_DETAIL_MASK_OFF
        mask *= tex2D(_DetailMask, s.baseUv).a;
    #endif
    
    #ifndef A_DETAIL_COLOR_MAP_OFF
        float2 detailUv = A_TRANSFORM_UV_SCROLL(s, _DetailAlbedoMap);
    #elif !defined(A_DETAIL_MATERIAL_MAP_OFF)
        float2 detailUv = A_TRANSFORM_UV_SCROLL(s, _DetailMaterialMap);
    #else
        float2 detailUv = A_TRANSFORM_UV_SCROLL(s, _DetailNormalMap);
    #endif
    
    #ifndef A_DETAIL_COLOR_MAP_OFF
        half3 detailAlbedo = tex2D(_DetailAlbedoMap, detailUv).rgb;
        half3 colorScale = _DetailMode < 0.5f ? half3(1.0h, 1.0h, 1.0h) : unity_ColorSpaceDouble.rgb;
        
        s.baseColor *= aLerpWhiteTo(detailAlbedo * colorScale, mask);
    #endif
    
    #ifndef A_DETAIL_MATERIAL_MAP_OFF
        half4 detailMaterial = tex2D(_DetailMaterialMap, detailUv);
        
        detailMaterial.y = GammaToLinearSpace(detailMaterial.yyy).x;
        s.ambientOcclusion *= aLerpOneTo(detailMaterial.y, mask * _DetailOcclusion);
        
        // Apply variance to roughness for detail Specular AA.
        // cf http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf pg92
        half a = s.roughness * s.roughness;
        a = sqrt(saturate((a * a) + detailMaterial.w * mask));
        s.roughness = sqrt(a);
    #endif

    #ifndef A_DETAIL_NORMAL_MAP_OFF
        half3 detailNormalTangent = UnpackScaleNormal(tex2D(_DetailNormalMap, detailUv), mask * _DetailNormalMapScale);
        s.normalTangent = BlendNormals(s.normalTangent, detailNormalTangent);
    #endif
#endif
} 

#endif // A_FEATURES_DETAIL_CGINC
