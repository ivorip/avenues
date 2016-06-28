// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file EyeOcclusion.cginc
/// @brief Eye Occlusion surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_EYE_OCCLUSION_CGINC
#define A_DEFINITIONS_EYE_OCCLUSION_CGINC

#define A_EXPANDED_MATERIAL_MAPS

#include "Assets/Alloy/Shaders/Lighting/EyeOcclusion.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

void aSurface(
    inout ASurface s)
{
    aDissolve(s);

    half4 base = aBaseColor(s);
    s.baseColor = base.rgb;
    s.opacity = base.a;

    s.ambientOcclusion = aAmbientOcclusion(tex2D(_AoMap, s.baseUv).gggg);
}

#endif // A_DEFINITIONS_EYE_OCCLUSION_CGINC
