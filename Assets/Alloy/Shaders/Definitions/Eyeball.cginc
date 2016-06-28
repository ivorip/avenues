// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Eyeball.cginc
/// @brief Eyeball surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_EYEBALL_CGINC
#define A_DEFINITIONS_EYEBALL_CGINC

#define A_SPECULAR_TINT_ON
#define A_CLEARCOAT_ON
#define A_PARALLAX_EYE_REFRACTION
#define A_DETAIL_MASK_OFF

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

/// Cornea normals.
/// Expects a compressed normal map.
sampler2D _EyeBumpMap;

/// Cornea weight.
/// Expects values in the range [0,1].
half _EyeCorneaWeight;

/// Cornea roughness.
/// Expects values in the range [0,1].
half _EyeRoughness;

/// Schlera tint color.
/// Expects a linear LDR color.
half3 _EyeScleraColor;

/// Iris tint color.
/// Expects a linear LDR color.
half3 _EyeColor;

/// Iris specular tint by base color.
/// Expects values in the range [0,1].
half _EyeSpecularTint;

void aSurface(
    inout ASurface s)
{
    float4 uv01 = s.uv01;
        
    aParallax(s);    
    aDissolve(s);
    
    half4 base = aBaseColor(s);
    s.baseColor = base.rgb;
    
    half4 material = aSampleMaterial(s);
    s.metallic = 0.0h;
    s.ambientOcclusion = aAmbientOcclusion(material); 
    s.specularity = aSpecularity(material);
    s.roughness = aRoughness(material);
    
    // Iris
    half irisMask = material.x;
    s.baseColor *= lerp(_EyeScleraColor, _EyeColor, irisMask);
    s.specularTint = irisMask * _EyeSpecularTint;
    
    // Cornea
    s.clearCoatWeight = _EyeCorneaWeight * irisMask;
    s.clearCoatRoughness = _EyeRoughness;
    
    half bumpMask = s.clearCoatWeight * 0.95h;
    half3 corneaNormalTangent = UnpackScaleNormal(tex2D(_EyeBumpMap, s.baseUv), bumpMask);
    s.normalTangent = aSampleBumpScale(s, 1.0h - bumpMask);
    s.normalTangent = BlendNormals(s.normalTangent, corneaNormalTangent);
    
    s.mask = 1.0h - irisMask;
    aDetail(s); 
    aNoBlend(s);
    
    aUpdateNormalData(s);
    aEmission(s);
    
    // Remove parallax so these appears on top of the cornea!
    s.uv01 = uv01;
    aDecal(s); 
    aRim(s);
}

#endif // A_DEFINITIONS_EYEBALL_CGINC
