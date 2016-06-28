// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file ForwardAdd.cginc
/// @brief Forward Add lighting vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_PASSES_FORWARD_ADD_CGINC
#define A_PASSES_FORWARD_ADD_CGINC

#include "AutoLight.cginc"

#define A_INSTANCING_OFF

struct AVertexToFragment {
    A_VERTEX_DATA(0, 1, 2, 3, 4, 5, 6)
    float4 lightVectorRange : TEXCOORD7;
    unityShadowCoord4 lightCoord : TEXCOORD8;
    SHADOW_COORDS(9)
    UNITY_VERTEX_OUTPUT_STEREO
};

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"

void aVertexShader(
    AVertex v,
    out AVertexToFragment o,
    out float4 opos : SV_POSITION)
{
    aTransferVertex(v, o, opos);
    aLightVectorRangeCoord(o.positionWorldAndViewDepth.xyz, o.lightVectorRange, o.lightCoord);
    UNITY_TRANSFER_FOG(o, opos);
    A_TRANSFER_SHADOW(o)
}

half4 aFragmentShader(
    AVertexToFragment i
    A_FACING_TYPE) : SV_Target
{
    ASurface s = aForwardSurface(i, A_FACING_SIGN);
    half3 illum = aForwardDirect(s, SHADOW_ATTENUATION(i), i.lightVectorRange, i.lightCoord);
    
    return aOutputForward(s, i, illum);
}			
            
#endif // A_PASSES_FORWARD_ADD_CGINC
