// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Skin.cginc
/// @brief Skin lighting model with SSS & Transmission. Deferred+Forward.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_LIGHTING_STANDARD_SKIN_CGINC
#define A_LIGHTING_STANDARD_SKIN_CGINC

#define A_SURFACE_CUSTOM_LIGHTING_DATA \
    half3 blurredNormalTangent; \
    half scatteringMask; \
    half shadowWeight; 

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

#ifdef A_FORWARD_ONLY
    #define A_SCATTERING_LUT _SssBrdfTex
    #define A_SCATTERING_ABSORPTION _SssTransmissionAbsorption
    #define A_SCATTERING_AO_COLOR_BLEED _SssColorBleedAoWeights
    #define A_SCATTERING_WEIGHT _SssScale
    #define A_SCATTERING_INV_MASK_CUTOFF 1.0h / _SssMaskCutoff
    #define A_SCATTERING_NORMAL_BLUR _SssBumpBlur

    #define A_TRANSMISSION_WEIGHT _TransWeight
    #define A_TRANSMISSION_SHADOW 0.0h
    #define A_TRANSMISSION_DISTORTION _TransDistortion
    #define A_TRANSMISSION_FALLOFF _TransPower
#else
    #define A_SCATTERING_LUT _DeferredSkinLut
    #define A_SCATTERING_ABSORPTION _DeferredSkinTransmissionAbsorption
    #define A_SCATTERING_AO_COLOR_BLEED _DeferredSkinColorBleedAoWeights
    #define A_SCATTERING_WEIGHT _DeferredSkinParams.x
    #define A_SCATTERING_INV_MASK_CUTOFF _DeferredSkinParams.y
    #define A_SCATTERING_NORMAL_BLUR _DeferredSkinParams.z

    #define A_TRANSMISSION_WEIGHT _DeferredTransmissionParams.x
    #define A_TRANSMISSION_SHADOW _DeferredTransmissionParams.w
    #define A_TRANSMISSION_DISTORTION _DeferredTransmissionParams.z
    #define A_TRANSMISSION_FALLOFF _DeferredTransmissionParams.y
#endif

#ifdef A_FORWARD_ONLY
    /// Pre-Integrated scattering LUT.
    sampler2D _SssBrdfTex;

    /// Per-channel weights for thickness-based transmission color absorption.
    half3 _SssTransmissionAbsorption;

    /// Per-channel RGB gamma weights for colored AO.
    /// Expects a vector of non-zero values.
    half3 _SssColorBleedAoWeights;

    /// Weight of the scattering effect.
    /// Expects values in the range [0,1].
    half _SssScale;

    /// Cutoff value used to convert tranmission data to scattering mask.
    /// Expects values in the range [0.01,1].
    half _SssMaskCutoff;

    /// Increases the bluriness of the normal map for diffuse lighting.
    /// Expects values in the range [0,1].
    half _SssBumpBlur;

    /// Weight of the transmission effect.
    /// Expects linear-space values in the range [0,1].
    half _TransWeight;

    /// Amount that the transmission is distorted by surface normals.
    /// Expects values in the range [0,1].
    half _TransDistortion;

    /// Falloff of the transmission effect.
    /// Expects values in the range [1,n).
    half _TransPower;
#else
    /// RGB=Blurred normals, A=Transmission thickness.
    /// Expects value in the buffer alpha.
    sampler2D _DeferredPlusBuffer;

    /// Pre-Integrated scattering LUT.
    sampler2D _DeferredSkinLut;

    /// Per-channel weights for thickness-based transmission color absorption.
    half3 _DeferredSkinTransmissionAbsorption;

    /// Per-channel RGB gamma weights for colored AO.
    /// Expects a vector of non-zero values.
    half3 _DeferredSkinColorBleedAoWeights;

    /// X=Scattering Weight, Y=1/Mask Cutoff, Z=Blur Weight.
    /// Expects a vector of non-zero values.
    half3 _DeferredSkinParams;

    /// X=Linear Weight, Y=Falloff, Z=Bump Distortion, W=Shadow Weight.
    /// Expects a vector of non-zero values.
    half4 _DeferredTransmissionParams;
#endif

half3 aSkinScattering(
    inout ASurface s,
    half3 normal,
    half3 blurredNormal)
{
    // Scattering mask.
    s.scatteringMask *= A_SCATTERING_WEIGHT * saturate(A_SCATTERING_INV_MASK_CUTOFF * s.transmission);

    // Skin depth absorption tint.
    // cf http://www.crytek.com/download/2014_03_25_CRYENGINE_GDC_Schultz.pdf pg 35
    half3 absorption = exp((1.0h - s.transmission) * A_SCATTERING_ABSORPTION);
    s.transmissionColor = s.albedo * GammaToLinearSpace(s.transmission.rrr);
    s.transmissionColor = A_TRANSMISSION_WEIGHT * lerp(s.transmissionColor, absorption, s.scatteringMask);

    // Blurred normals for indirect diffuse and direct scattering.
    return normalize(lerp(normal, blurredNormal, A_SCATTERING_NORMAL_BLUR * s.scatteringMask));
}

void aPreSurface(
    inout ASurface s)
{
    s.blurredNormalTangent = A_FLAT_NORMAL;
}

void aPostSurface(
    inout ASurface s)
{
    s.materialType = 0.0h;
    s.scatteringMask = 1.0h;
    s.blurredNormalTangent = aSkinScattering(s, s.normalTangent, s.blurredNormalTangent);
    s.ambientNormalWorld = aNormalWorld(s, s.blurredNormalTangent);
    s.shadowWeight = A_TRANSMISSION_SHADOW;
}

void aGbufferSurface(
    inout ASurface s)
{
#ifndef A_FORWARD_ONLY
    half4 buffer = tex2D(_DeferredPlusBuffer, s.screenUv);
    s.transmission = 1.0h - buffer.a;
    s.shadowWeight = 0.75 < s.materialType ? A_TRANSMISSION_SHADOW : 0.0h;
    s.scatteringMask = 0.5h < s.materialType ? 0.0h : 1.0h;
    s.ambientNormalWorld = aSkinScattering(s, s.normalWorld, normalize(buffer.xyz * 2.0h - 1.0h));
#endif
}

half3 aDirect( 
    ADirect d,
    ASurface s)
{
    return aStandardDirect(d, s, 1.0h - s.scatteringMask)
        + aStandardSkin(d, s, A_SCATTERING_LUT, s.scatteringMask)
        + aStandardTransmission(d, s, A_TRANSMISSION_DISTORTION, A_TRANSMISSION_FALLOFF, s.shadowWeight);
}

half3 aIndirect(
    AIndirect i,
    ASurface s)
{
    // Color Bleed AO.
    // cf http://www.iryoku.com/downloads/Next-Generation-Character-Rendering-v6.pptx pg113
    i.diffuse *= pow(s.ambientOcclusion, half3(1.0h, 1.0h, 1.0h) - (A_SCATTERING_AO_COLOR_BLEED * s.scatteringMask));
    s.ambientOcclusion = 1.0h;
    return aStandardIndirect(i, s);
}

#endif // A_LIGHTING_STANDARD_SKIN_CGINC
