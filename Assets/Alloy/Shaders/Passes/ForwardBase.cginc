// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file ForwardBase.cginc
/// @brief Forward Base lighting vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_PASSES_FORWARD_BASE_CGINC
#define A_PASSES_FORWARD_BASE_CGINC

#include "AutoLight.cginc"

struct AVertexToFragment {
    A_VERTEX_DATA(0, 1, 2, 3, 4, 5, 6)
#ifndef A_LIGHTING_OFF
    A_GI_DATA(7)
    SHADOW_COORDS(8)
#endif
    UNITY_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"

void aVertexShader(
    AVertex v,
    out AVertexToFragment o,
    out float4 opos : SV_POSITION)
{
    aTransferVertex(v, o, opos);
    aVertexGi(v, o);
    A_TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, opos);
}

half4 aFragmentShader(
    AVertexToFragment i
    A_FACING_TYPE) : SV_Target
{
    ASurface s = aForwardSurface(i, A_FACING_SIGN);
    half3 illum = s.emission;

#ifndef A_LIGHTING_OFF
    half shadow = SHADOW_ATTENUATION(i);
    UnityGI gi = aFragmentGi(s, i, shadow);

    illum += aGlobalIllumination(gi, s);

    #ifdef LIGHTMAP_OFF
        illum += aForwardDirect(s, shadow, _WorldSpaceLightPos0, unityShadowCoord4(0, 0, 0, 0));
    #endif
#endif

    return aOutputForward(s, i, illum);
}
            
#endif // A_PASSES_FORWARD_BASE_CGINC
