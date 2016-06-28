// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Skin.cginc
/// @brief Skin surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_SKIN_CGINC
#define A_DEFINITIONS_SKIN_CGINC

#define A_DETAIL_FALLOFF_ON

// NOTE: The example shader used calculated curvature, but it looked terrible. 
// We're using a translucency map, and getting much better results.
#define A_SURFACE_CUSTOM_LIGHTING_DATA \
    half3 blurredNormalTangent; \
    half scatteringMask; \
    half scattering; 

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

// Jon Moore recommended this value in his blog post.
#define A_SKIN_BUMP_BLUR_BIAS (3.0)

sampler2D _SssBrdfTex;

/// Biases the thickness value used to look up in the skin LUT.
/// Expects values in the range [0,1].
half _SssBias;

/// Scales the thickness value used to look up in the skin LUT.
/// Expects values in the range [0,1].
half _SssScale;

/// Amount to colorize and darken AO to simulate local scattering.
/// Expects values in the range [0,1].
half _SssAoSaturation;

/// Increases the bluriness of the normal map for diffuse lighting.
/// Expects values in the range [0,1].
half _SssBumpBlur;

/// Transmission tint color.
/// Expects a linear LDR color.
half3 _TransColor;

/// Weight of the transmission effect.
/// Expects linear space value in the range [0,1].
half _TransScale;

/// Falloff of the transmission effect.
/// Expects values in the range [1,n).
half _TransPower;

/// Amount that the transmission is distorted by surface normals.
/// Expects values in the range [0,1].
half _TransDistortion;

/// Calculates standard indirect diffuse plus specular illumination.
/// @param  d       Direct light description.
/// @param  s       Material surface data.
/// @param  skinLut Pre-Integrated scattering LUT.
/// @return         Direct diffuse illumination with scattering effect.
half3 aLegacySkin(
    ADirect d,
    ASurface s,
    sampler2D skinLut)
{
    // Scattering
    // cf http://www.farfarer.com/blog/2013/02/11/pre-integrated-skin-shader-unity-3d/
    float ndlBlur = dot(s.ambientNormalWorld, d.direction) * 0.5h + 0.5h;
    float2 sssLookupUv = float2(ndlBlur, s.scattering * aLuminance(d.color));
    half3 sss = s.scatteringMask * d.shadow * tex2D(skinLut, sssLookupUv).rgb;

    //#if !defined(SHADOWS_SCREEN) && !defined(SHADOWS_DEPTH) && !defined(SHADOWS_CUBE)
    //    // If shadows are off, we need to reduce the brightness
    //    // of the scattering on polys facing away from the light.		
    //    sss *= saturate(ndlBlur * 4.0h - 1.0h); // [-1,3], then clamp
    //#else
    //    sss *= d.shadow;
    //#endif

    return d.color * s.albedo * sss;
}

/// Calculates direct light transmission effect using per-pixel thickness.
/// @param d                    Indirect light description.
/// @param s                    Material surface data.
/// @param weight               Weight of the transmission effect.
/// @param distortion           Distortion due to surface normals.
/// @param falloff              Tightness of the transmitted light.
/// @param shadowWeight         Amount that the transsmision is shadowed.
/// @return                     Transmission effect.
half3 aLegacyTransmission(
    ADirect d,
    ASurface s,
    half weight,
    half distortion,
    half falloff,
    half shadowWeight)
{
    // Transmission 
    // cf http://www.farfarer.com/blog/2012/09/11/translucent-shader-unity3d/
    half3 transLightDir = d.direction + s.normalWorld * distortion;
    half transLight = pow(aDotClamp(s.viewDirWorld, -transLightDir), falloff);

    transLight *= weight * aLerpOneTo(d.shadow, shadowWeight);
    return d.color * s.transmissionColor * transLight;
}

void aPreSurface(
    inout ASurface s)
{
    s.scatteringMask = 1.0h;
    s.blurredNormalTangent = A_FLAT_NORMAL;
}

void aPostSurface(
    inout ASurface s)
{
    // Blurred normals for indirect diffuse and direct scattering.
    s.blurredNormalTangent = normalize(lerp(s.normalTangent, s.blurredNormalTangent, s.scatteringMask * _SssBumpBlur));
    s.ambientNormalWorld = aNormalWorld(s, s.blurredNormalTangent);
    s.transmissionColor = _TransScale * _TransColor * s.albedo * s.transmission.rrr;
    s.scattering = saturate(s.transmission * _SssScale + _SssBias);
}

half3 aDirect(
    ADirect d,
    ASurface s)
{
    return aStandardDirect(d, s, 1.0h - s.scatteringMask)
        + aLegacySkin(d, s, _SssBrdfTex)
        + aLegacyTransmission(d, s, 1.0h, _TransDistortion, _TransPower, 0.0h);
}

half3 aIndirect(
    AIndirect i,
    ASurface s)
{
    // Saturated AO.
    // cf http://www.iryoku.com/downloads/Next-Generation-Character-Rendering-v6.pptx pg110
    half saturation = s.scatteringMask * _SssAoSaturation;

    s.albedo = pow(s.albedo, (1.0h + saturation) - saturation * s.ambientOcclusion);
    return aStandardIndirect(i, s);
}

#include "Assets/Alloy/Shaders/Models/Standard.cginc"

void aSurface(
    inout ASurface s)
{
    aDissolve(s);
    
    half4 base = aBaseColor(s);
    s.baseColor = base.rgb;
    s.transmission = GammaToLinearSpace(base.aaa).r;
    
    half4 material = aSampleMaterial(s);
    s.scatteringMask = material.x;
    s.ambientOcclusion = aAmbientOcclusion(material); 
    s.specularity = aSpecularity(material);
    s.roughness = aRoughness(material);
    
    s.normalTangent = aSampleBump(s);
    s.blurredNormalTangent = aSampleBumpBias(s, A_SKIN_BUMP_BLUR_BIAS);
    
    aDetail(s);
    aTeamColor(s);
    aDecal(s);
    aUpdateNormalData(s);	
    aRim(s);
    aEmission(s);
}

#endif // A_DEFINITIONS_SKIN_CGINC
