// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file MainTextures.cginc
/// @brief Main set of textures.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_MAIN_TEXTURES_CGINC
#define A_FEATURES_MAIN_TEXTURES_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

/// Applies the Main Textures feature to the given material data.
/// @param[in,out] s Material surface data.
void aMainTextures(
    inout ASurface s)
{
#ifdef A_MAIN_TEXTURES_ON
    half4 base = aBaseColor(s);
    s.baseColor = base.rgb;
    
    #ifdef _MAINROUGHNESSSOURCE_BASECOLORALPHA
        s.metallic = _Metal;
        s.specularity = _Specularity;
        s.roughness = aRoughness(base.aaaa);
    #else
        s.opacity = base.a;

        #ifndef A_MAIN_TEXTURES_CUTOUT_OFF
            aCutout(s);
        #endif
    
        #ifndef A_MAIN_TEXTURES_MATERIAL_MAP_OFF
            half4 material = aSampleMaterial(s);    
            s.metallic = aMetallic(material);
            s.ambientOcclusion = aAmbientOcclusion(material);
            s.specularity = aSpecularity(material);
            s.roughness = aRoughness(material);
        #endif
    #endif

    s.normalTangent = aSampleBump(s);
#endif
}

#endif // A_FEATURES_MAIN_TEXTURES_CGINC
