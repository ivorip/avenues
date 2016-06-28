// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Lighting.cginc
/// @brief Lighting uber-header.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_LIGHTING_CGINC
#define A_FRAMEWORK_LIGHTING_CGINC

/// Needed to prevent z-fighting on Forward Add when using instancing.
#if !defined(UNITY_USE_CONCATENATED_MATRICES) && defined(INSTANCING_ON) && defined(UNITY_PASS_FORWARDADD)
    #define UNITY_USE_CONCATENATED_MATRICES 
#endif

// NOTE: Config comes first to override Unity settings!
#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Brdf.cginc"
#include "Assets/Alloy/Shaders/Framework/Direct.cginc"
#include "Assets/Alloy/Shaders/Framework/Indirect.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityStandardBRDF.cginc"

#if !defined(A_REFLECTION_PROBES_OFF) && defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
    #define A_REFLECTION_PROBES_OFF
#endif

// Jon Moore recommended this value in his blog post.
#define A_SKIN_BUMP_BLUR_BIAS (3.0)

/// Calculates standard direct diffuse plus specular illumination.
/// @param d                Direct light description.
/// @param s                Material surface data.
/// @param diffuseWeight    Material surface data.
/// @return                 Direct illumination.
half3 aStandardDirect(
    ADirect d,
    ASurface s,
    half diffuseWeight)
{
    // Punctual light equation, with Cook-Torrance microfacet model.
    return d.color * (d.shadow * d.NdotL) * (
        aDiffuseBrdf(s.albedo, s.roughness, d.LdotH, d.NdotL, s.FV) * diffuseWeight
        + (s.specularOcclusion * d.specularIntensity
            * aSpecularBrdf(s.f0, s.beckmannRoughness, d.LdotH, d.NdotH, d.NdotL, s.NdotV)));
}

/// Calculates standard direct diffuse plus specular illumination.
/// @param d                Direct light description.
/// @param s                Material surface data.
/// @return                 Direct illumination.
half3 aStandardDirect(
    ADirect d,
    ASurface s)
{
    return aStandardDirect(d, s, 1.0h);
}

/// Calculates standard indirect diffuse plus specular illumination.
/// @param d    Indirect light description.
/// @param s    Material surface data.
/// @return     Indirect illumination.
half3 aStandardIndirect(
    AIndirect i,
    ASurface s)
{
    // Yoshiharu Gotanda's fake interreflection for specular occlusion.
    // Modified to better account for surface f0.
    // cf http://research.tri-ace.com/Data/cedec2011_RealtimePBR_Implementation_e.pptx pg65
    half3 ambient = i.diffuse * s.ambientOcclusion;

#ifdef A_REFLECTION_PROBES_OFF
    // Diffuse and fake interreflection only.
    return ambient * (s.albedo + s.f0 * (1.0h - s.specularOcclusion));
#else
    // Full equation.
    return ambient * s.albedo
        + lerp(ambient * s.f0, i.specular * aEnvironmentBrdf(s.f0, s.roughness, s.NdotV), s.specularOcclusion);
#endif
}

/// Calculates standard indirect diffuse plus specular illumination.
/// @param  d       Direct light description.
/// @param  s       Material surface data.
/// @param  skinLut Pre-Integrated scattering LUT.
/// @param  weight  Weight of the effect.
/// @return         Direct diffuse illumination with scattering effect.
half3 aStandardSkin(
    ADirect d,
    ASurface s,
    sampler2D skinLut,
    half weight)
{
    // Pre-Integrated Skin Shading.
    // cf http://www.farfarer.com/blog/2013/02/11/pre-integrated-skin-shader-unity-3d/
    float ndlBlur = dot(s.ambientNormalWorld, d.direction) * 0.5h + 0.5h;
    float2 sssLookupUv = float2(ndlBlur, s.transmission * aLuminance(d.color));
    half3 sss = weight * d.shadow * tex2D(skinLut, sssLookupUv).rgb;

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
/// @param distortion           Distortion due to surface normals.
/// @param falloff              Tightness of the transmitted light.
/// @param shadowWeight         Amount that the transsmision is shadowed.
/// @return                     Transmission effect.
half3 aStandardTransmission(
    ADirect d,
    ASurface s,
    half distortion,
    half falloff,
    half shadowWeight)
{
    // Transmission.
    // cf http://www.farfarer.com/blog/2012/09/11/translucent-shader-unity3d/
    half3 transLightDir = d.direction + s.normalWorld * distortion;
    half transLight = pow(aDotClamp(s.viewDirWorld, -transLightDir), falloff);
    half shadow = aLerpOneTo(d.shadow, shadowWeight);

    return d.color * s.transmissionColor * (shadow * transLight);
}

#endif // A_FRAMEWORK_LIGHTING_CGINC
