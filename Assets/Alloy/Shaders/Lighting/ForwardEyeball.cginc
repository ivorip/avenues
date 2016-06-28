// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Eyeball.cginc
/// @brief Eyeball lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_LIGHTING_EYEBALL_CGINC
#define A_LIGHTING_EYEBALL_CGINC

#define A_VIEW_VECTOR_TANGENT_ON

#define A_SURFACE_CUSTOM_LIGHTING_DATA \
    half scattering; \
    half irisMask; \
    half corneaSpecularity; \
    half corneaRoughness; \
    half3 corneaNormalWorld; \
    half3 irisF0; \
    half irisSpecularOcclusion; \
    half irisRoughness; \
    half irisBeckmannRoughness; \
    half irisNdotV;

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

/// Implements a scattering diffuse BRDF affected by roughness.
/// @param  albedo      Diffuse albedo LDR color.
/// @param  subsurface  Blend value between diffuse and scattering [0,1].
/// @param  roughness   Linear roughness [0,1].
/// @param  LdotH       Light and half-angle clamped dot product [0,1].
/// @param  NdotL       Normal and light clamped dot product [0,1].
/// @param  NdotV       Normal and view clamped dot product [0,1].
/// @return             Direct diffuse BRDF.
half3 aDiffuseBssrdf(
    half3 albedo,
    half subsurface,
    half roughness,
    half LdotH,
    half NdotL,
    half NdotV)
{
    // Impelementation of Brent Burley's diffuse scattering BRDF.
    // Subject to Apache License, version 2.0
    // cf https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf
    half FL = aFresnel(NdotL);
    half FV = aFresnel(NdotV);
    half Fss90 = LdotH * LdotH * roughness;
    half Fd90 = 0.5h + (2.0h * Fss90);
    half Fd = aLerpOneTo(Fd90, FL) * aLerpOneTo(Fd90, FV);
    half Fss = aLerpOneTo(Fss90, FL) * aLerpOneTo(Fss90, FV);
    half ss = 1.25h * (Fss * (1.0h / max(NdotL + NdotV, A_EPSILON) - 0.5h) + 0.5h);
    
    // Pi is cancelled by implicit punctual lighting equation.
    // cf http://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    return albedo * lerp(Fd, ss, subsurface);
}

void aPreSurface(
    inout ASurface s)
{
    s.scattering = 0.0h;
    s.irisMask = 0.0h;
    s.corneaSpecularity = 0.36h;
    s.corneaRoughness = 0.0h;
}

void aPostSurface(
    inout ASurface s)
{
    // Tint the iris specular to fake caustics.
    // cf http://game.watch.impress.co.jp/docs/news/20121129_575412.html

    // Iris & Sclera
    s.irisNdotV = s.NdotV; 
    s.irisSpecularOcclusion = aSpecularOcclusion(s.ambientOcclusion, s.irisNdotV);
    s.irisF0 = s.f0;
    s.irisRoughness = s.roughness;
    s.irisBeckmannRoughness = aLinearToBeckmannRoughness(s.irisRoughness);
    s.ambientNormalWorld = s.normalWorld;

    // Cornea
    half3 corneaNormal = lerp(s.normalTangent, A_FLAT_NORMAL, s.irisMask);
    s.corneaNormalWorld = aNormalWorld(s, corneaNormal);

    s.reflectionVectorWorld = reflect(-s.viewDirWorld, s.corneaNormalWorld);
    s.NdotV = aDotClamp(s.corneaNormalWorld, s.viewDirWorld);
    
    s.specularOcclusion = lerp(s.irisSpecularOcclusion, 1.0h, s.irisMask);
    s.f0 = lerp(s.f0, aSpecularityToF0(s.corneaSpecularity), s.irisMask);
    s.roughness = lerp(s.roughness, s.corneaRoughness, s.irisMask);
    s.beckmannRoughness = aLinearToBeckmannRoughness(s.roughness);
}

half3 aDirect( 
    ADirect d,
    ASurface s)
{
    half3 illum = 0.0h;
    
    // Iris & Sclera		
    illum = d.NdotL * (
        aDiffuseBssrdf(s.albedo, s.scattering, s.irisRoughness, d.LdotH, d.NdotL, s.irisNdotV));
                //+ (s.irisSpecularOcclusion * AlloyAreaLightNormalization(s.irisBeckmannRoughness, d.solidAngle)
                //	* aSpecularBrdf(s.irisF0, s.irisBeckmannRoughness, d.LdotH, d.NdotH, d.NdotL, s.irisNdotV)));
                        
    // Cornea
    half NdotH = aDotClamp(s.corneaNormalWorld, d.halfAngleWorld);
    half NdotL = aDotClamp(s.corneaNormalWorld, d.direction);
    
    illum += (s.irisMask * NdotL * s.specularOcclusion * d.specularIntensity)
                * aSpecularBrdf(s.f0, s.beckmannRoughness, d.LdotH, NdotH, NdotL, s.NdotV);
    
    return illum * d.color * d.shadow;
}

half3 aIndirect(
    AIndirect i,
    ASurface s)
{
    return aStandardIndirect(i, s);
}

#endif // A_LIGHTING_EYEBALL_CGINC
