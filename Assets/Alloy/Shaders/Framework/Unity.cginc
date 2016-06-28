// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Unity.cginc
/// @brief Functions shared between Alloy shaders and Unity injection headers.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_UNITY_CGINC
#define A_FRAMEWORK_UNITY_CGINC

#include "Assets/Alloy/Shaders/Framework/Direct.cginc"
#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "AutoLight.cginc"
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityShaderVariables.cginc"

/// Calculates specular inputs.
/// @param[in,out] s Material surface data.
void aUpdateSpecularData(
    inout ASurface s)
{
    s.beckmannRoughness = aLinearToBeckmannRoughness(s.roughness);
    s.specularOcclusion = aSpecularOcclusion(s.ambientOcclusion, s.NdotV);
    aPostSurface(s);
}

/// Calculates and sets PBR BRDF inputs.
/// @param[in,out] s Material surface data.
void aUpdateBrdfData(
    inout ASurface s)
{
    half metallicInv = 1.0h - s.metallic;
    half3 dielectricF0 = aSpecularityToF0(s.specularity);

    // Ensures energy-conserving color when using weird detail modes.
    s.baseColor = saturate(s.baseColor);

#ifdef A_SPECULAR_TINT_ON
    dielectricF0 *= aSpecularTint(s.baseColor, s.specularTint);
#endif

    s.albedo = s.baseColor * metallicInv;
    s.f0 = lerp(dielectricF0, s.baseColor, s.metallic);

#ifdef A_CLEARCOAT_ON
    // Specularity of 0.5 gives us a polyurethane like coating.
    half clearCoatWeight = 0.5h * s.clearCoatWeight;
    s.f0 += aSpecularityToF0(clearCoatWeight);
    s.f0 = saturate(s.f0);
    s.roughness = lerp(s.roughness, s.clearCoatRoughness, clearCoatWeight);
#endif
#ifdef _ALPHAPREMULTIPLY_ON
    // Interpolate from a translucent dielectric to an opaque metal.
    s.opacity = s.metallic + metallicInv * s.opacity;

    // Premultiply opacity with albedo for translucent shaders.
    s.albedo *= s.opacity;
#endif

    // Transmission can't happen through metal.
    s.transmission *= metallicInv;
    aUpdateSpecularData(s);
}

/// Calculates direct lighting from a UnityLight object.
/// @param  light   UnityLight populated with data.
/// @param  s       Material surface data.
/// @return         Direct illumination.
half3 aUnityLightDirect(
    UnityLight light,
    ASurface s)
{	
#ifdef A_LIGHTING_OFF
    return 0.0h;
#else
    // NOTE: Can't reuse lightmap N.L, since it used ambient normal.
    ADirect d = aCreateDirect();
    d.color = light.color;
    d.direction = light.dir;
    aDirectionalLight(d, s);
    return aDirect(d, s);
#endif
}

/// Calculates global illumination from UnityGI data.
/// @param  gi      UnityGI populated with data.
/// @param  s       Material surface data.
/// @return         Indirect illumination.
half3 aGlobalIllumination(
    UnityGI gi,
    ASurface s)
{
#ifdef A_GI_OFF
    return 0.0h;
#else
    half3 illum = aIndirect(gi.indirect, s);
    
    #ifdef DIRLIGHTMAP_SEPARATE
        #ifdef LIGHTMAP_ON
            // Static Direct
            illum += aUnityLightDirect(gi.light, s);
        #endif

        s.albedo *= s.ambientOcclusion;
    
        #ifdef LIGHTMAP_ON
            // Static Indirect
            illum += aUnityLightDirect(gi.light2, s);
        #endif
        #ifdef DYNAMICLIGHTMAP_ON
            // Dynamic Indirect
            illum += aUnityLightDirect(gi.light3, s);
        #endif
    #endif
    
    return illum;
#endif
}

/// Calculates light vectors per-vertex.
/// @param[in]  positionWorld       Position in world-space.
/// @param[out] lightVectorRange    XYZ: Vector to light center, W: Light volume range.
/// @param[out] lightCoord          Projection coordinates in light space.
void aLightVectorRangeCoord(
    float3 positionWorld,
    out float4 lightVectorRange,
    out unityShadowCoord4 lightCoord)
{
    lightVectorRange = UnityWorldSpaceLightDir(positionWorld).xyzz;

#ifdef DIRECTIONAL
    lightCoord = 0.0h;
#else
    lightCoord = mul(unity_WorldToLight, unityShadowCoord4(positionWorld, 1.0f));

    #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
        // Trick to obtain light range for point lights from projected coordinates.
        // cf http://forum.unity3d.com/threads/get-the-range-of-a-point-light-in-forward-add-mode.213430/#post-1433291
        lightVectorRange.w = length(lightVectorRange.xyz) * rsqrt(dot(lightCoord.xyz, lightCoord.xyz));
    #endif
#endif
}

/// Calculates forward direct illumination.
/// @param  s                   Material surface data.
/// @param  shadow              Shadow attenuation.
/// @param  lightVectorRange    XYZ: Vector to light center, W: Light volume range.
/// @param  lightCoord          Light projection texture coordinates.
/// @return                     Direct illumination.
half3 aForwardDirect(
    ASurface s,
    half shadow,
    float4 lightVectorRange,
    unityShadowCoord4 lightCoord)
{
#ifdef A_LIGHTING_OFF
    return 0.0h;
#else
    ADirect d = aCreateDirect();
    half3 lightAxis = 0.0h;

    d.color = _LightColor0.rgb;
    d.shadow = shadow;
        
    #ifdef USING_DIRECTIONAL_LIGHT
        #if !defined(ALLOY_SUPPORT_REDLIGHTS) && defined(DIRECTIONAL_COOKIE)
            aLightCookie(d, tex2D(_LightTexture0, lightCoord.xy));
        #endif
    #elif defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
        lightAxis = normalize(unity_WorldToLight[1].xyz);

        #if defined(POINT)
            A_UNITY_ATTENUATION(d, _LightTexture0, lightCoord.xyz, 1.0f)
        #elif defined(POINT_COOKIE)
            aLightCookie(d, texCUBE(_LightTexture0, lightCoord.xyz));
            A_UNITY_ATTENUATION(d, _LightTextureB0, lightCoord.xyz, 1.0f)
        #elif defined(SPOT)
            half4 cookie = tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5);
        
            cookie.a *= (lightCoord.z > 0);
            aLightCookie(d, cookie);
            A_UNITY_ATTENUATION(d, _LightTextureB0, lightCoord.xyz, 1.0f)
        #endif
    #endif

    #if !(defined(ALLOY_SUPPORT_REDLIGHTS) && defined(DIRECTIONAL_COOKIE))
        aAreaLight(d, s, _LightColor0, lightAxis, lightVectorRange.xyz, lightVectorRange.w);
    #else
        d.direction = lightVectorRange.xyz;
        d.color *= redLightCalculateForward(_LightTexture0, s.positionWorld, s.normalWorld, s.viewDirWorld, d.direction);
        aDirectionalLight(d, s);
    #endif

    return aDirect(d, s);
#endif
}

/// Forward illumination with Unity inputs.
/// @param s        Material surface data.
/// @param gi       Unity GI descriptor.
/// @param shadow   Shadow for the given direct light.
/// @return         Combined lighting, emission, etc.
half4 aUnityOutputForward(
    ASurface s,
    UnityGI gi,
    half shadow)
{
    half4 c = 0.0h;

#ifdef UNITY_PASS_FORWARDBASE
    c.rgb = aGlobalIllumination(gi, s);
#endif
#ifndef LIGHTMAP_ON
    float4 lightVectorRange = 0.0h;
    unityShadowCoord4 lightCoord = 0.0f;

    aLightVectorRangeCoord(s.positionWorld, lightVectorRange, lightCoord);
    c.rgb += aForwardDirect(s, shadow, lightVectorRange, lightCoord);
#endif
    c.a = s.opacity;

    c.rgb = aHdrClamp(c.rgb);
    return c;
}

/// Populates the G-buffer with Unity-compatible material data.
/// @param[in]  s                   Material surface data.
/// @param[in]  gi                  Unity GI descriptor.
/// @param[out] outDiffuseOcclusion RGB: albedo, A: specular occlusion.
/// @param[out] outSpecSmoothness   RGB: f0, A: 1-roughness.
/// @param[out] outNormal           RGB: packed normal, A: 1-scattering mask.
/// @return                         RGB: emission, A: 1-transmission.
half4 aUnityOutputDeferred(
    ASurface s,
    UnityGI gi,
    out half4 outDiffuseOcclusion,
    out half4 outSpecSmoothness,
    out half4 outNormal)
{
#ifndef UNITY_PASS_DEFERRED
    return 0.0h;
#else
    half4 outEmission = half4(s.emission, 1.0h - s.transmission);
    outDiffuseOcclusion = half4(s.albedo, s.specularOcclusion);
    outSpecSmoothness = half4(s.f0, 1.0h - s.roughness);
    outNormal = half4(s.normalWorld * 0.5h + 0.5h, s.materialType);

    #ifndef A_GI_OFF
        outEmission.rgb += aGlobalIllumination(gi, s);
    #endif
    return aHdrClamp(outEmission);
#endif
}

#endif // A_FRAMEWORK_UNITY_CGINC
