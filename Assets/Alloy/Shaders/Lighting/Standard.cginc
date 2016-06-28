// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Standard.cginc
/// @brief Standard lighting model. Deferred+Forward.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_LIGHTING_STANDARD_CGINC
#define A_LIGHTING_STANDARD_CGINC

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void aPreSurface(
    inout ASurface s)
{

}

void aPostSurface(
    inout ASurface s)
{
    s.ambientNormalWorld = s.normalWorld;
    s.materialType = 1.0h;
    s.transmission = 0.0h;
}

void aGbufferSurface(
    inout ASurface s)
{

}

half3 aDirect( 
    ADirect d,
    ASurface s)
{
    return aStandardDirect(d, s);
}

half3 aIndirect(
    AIndirect i,
    ASurface s)
{
    return aStandardIndirect(i, s);
}

#endif // A_LIGHTING_STANDARD_CGINC
