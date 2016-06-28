// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file EyeOcclusion.cginc
/// @brief EyeOcclusion lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_LIGHTING_EYE_OCCLUSION_CGINC
#define A_LIGHTING_EYE_OCCLUSION_CGINC

#define A_REFLECTION_PROBES_OFF

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void aPreSurface(
    inout ASurface s)
{

}

void aPostSurface(
    inout ASurface s)
{
    s.opacity *= (1.0h - s.specularOcclusion);
    s.ambientNormalWorld = s.normalWorld;
}

half3 aDirect( 
    ADirect d,
    ASurface s)
{
    return d.color * (d.shadow * d.NdotL * s.ambientOcclusion) * s.albedo;
}

half3 aIndirect(
    AIndirect i,
    ASurface s)
{
    return i.diffuse * s.ambientOcclusion * s.albedo;
}

#endif // A_LIGHTING_EYE_OCCLUSION_CGINC
