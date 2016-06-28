// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Meta.cginc
/// @brief Meta vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_PASSES_META_CGINC
#define A_PASSES_META_CGINC

#include "UnityMetaPass.cginc"

struct AVertexToFragment {
    A_VERTEX_DATA(0, 1, 2, 3, 4, 5, 6)
};

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"

void aVertexShader(
    AVertex v,
    out AVertexToFragment o,
    out float4 opos : SV_POSITION)
{
    aTransferVertex(v, o, opos);
    opos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
}

float4 aFragmentShader(
    AVertexToFragment i) : SV_Target
{
    UnityMetaInput o;
    ASurface s = aForwardSurface(i, 1.0h);

    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
    o.Albedo = s.baseColor;
    o.Emission = aHdrClamp(s.emission);

    return UnityMetaFragment(o);
}
            
#endif // A_PASSES_META_CGINC
