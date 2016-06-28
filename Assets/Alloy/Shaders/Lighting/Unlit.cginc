// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Unlit.cginc
/// @brief Unlit lighting model. Deferred+Forward.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_LIGHTING_UNLIT_CGINC
#define A_LIGHTING_UNLIT_CGINC

#define A_LIGHTING_OFF

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void aPreSurface(
    inout ASurface s)
{

}

void aPostSurface(
    inout ASurface s)
{
    s.ambientNormalWorld = s.normalWorld;
    s.albedo = 0.0h;
    s.specularOcclusion = 0.0h;
    s.f0 = 0.0h;
    s.roughness = 1.0h;
    s.materialType = 1.0h;
    s.transmission = 0.0h;
}

#endif // A_LIGHTING_UNLIT_CGINC
