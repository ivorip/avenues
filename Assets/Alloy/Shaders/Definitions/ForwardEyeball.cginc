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
#define A_PARALLAX_EYE_REFRACTION
#define A_DETAIL_MASK_OFF

#include "Assets/Alloy/Shaders/Lighting/ForwardEyeball.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

/// Schlera tint color.
/// Expects a linear LDR color.
half3 _EyeScleraColor;

/// Schlera diffuse scattering amount.
/// Expects values in the range [0,1].
half _EyeScleraScattering;

/// Cornea specularity.
/// Expects values in the range [0,1].
half _EyeSpecularity;

/// Cornea roughness.
/// Expects values in the range [0,1].
half _EyeRoughness;

/// Iris tint color.
/// Expects a linear LDR color.
half3 _EyeColor;

/// Iris diffuse scattering amount.
/// Expects values in the range [0,1].
half _EyeIrisScattering;

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
    s.irisMask = material.x;
    s.ambientOcclusion = aAmbientOcclusion(material); 
    s.specularity = aSpecularity(material);
    s.roughness = aRoughness(material);
    
    s.normalTangent = aSampleBump(s);
    
    s.baseColor *= lerp(_EyeScleraColor, _EyeColor, s.irisMask);
    s.specularTint = s.irisMask * _EyeSpecularTint;
    s.scattering = lerp(_EyeScleraScattering, _EyeIrisScattering, s.irisMask);
    s.corneaSpecularity = _EyeSpecularity;
    s.corneaRoughness = _EyeRoughness;
    
    // Don't allow detail normals in the iris.
    s.mask = 1.0h - s.irisMask;
    aDetail(s); 
    aNoBlend(s);
    
    aUpdateNormalData(s);
    aEmission(s);
    aRim(s);
    
    // Remove parallax so this appears on top of the cornea!
    s.uv01 = uv01;
    aDecal(s); 
}

#endif // A_DEFINITIONS_EYEBALL_CGINC
