// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Deferred.cginc
/// @brief Deferred g-buffer vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_PASSES_DEFERRED_CGINC
#define A_PASSES_DEFERRED_CGINC

struct AVertexToFragment {
    A_VERTEX_DATA(0, 1, 2, 3, 4, 5, 6)
    A_GI_DATA(7)
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
}

void aFragmentShader(
    AVertexToFragment i
    A_FACING_TYPE,
    out half4 outDiffuseOcclusion : SV_Target0,
    out half4 outSpecSmoothness : SV_Target1,
    out half4 outNormal : SV_Target2,
    out half4 outEmission : SV_Target3)
{
    aOutputDeferred(i, A_FACING_SIGN, outDiffuseOcclusion, outSpecSmoothness, outNormal, outEmission);
}					
            
#endif // A_PASSES_DEFERRED_CGINC
