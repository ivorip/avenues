// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Nature/SpeedTree" {
Properties {
    // Settings
    _GeometryType ("'Geometry Type' {SpeedTreeGeometryType:{Branch:{_Cutoff,_DetailTex,_DetailNormalMap,_TransTex,_TransScale}, BranchDetail:{_Cutoff,_TransTex,_TransScale}, Frond:{_Cutoff,_DetailTex,_DetailNormalMap}, Leaf:{_DetailTex,_DetailNormalMap}, Mesh:{_Cutoff,_DetailTex,_DetailNormalMap,_TransTex,_TransScale}}}", Float) = 0
    [LM_TransparencyCutOff] 
    _Cutoff ("'Alpha Cutoff' {Min:0, Max:1}", Float) = 0.333
    [MaterialEnum(Off,0,Front,1,Back,2)] 
    _Cull ("'Cull Mode' {Dropdown:{Off:{}, Front:{}, Back:{}}}", Int) = 2
    [MaterialEnum(None,0,Fastest,1,Fast,2,Better,3,Best,4,Palm,5)] 
    _WindQuality ("'Wind Quality' {Dropdown:{None:{}, Fastest:{}, Fast:{}, Better:{}, Best:{}, Palm:{}}}", Float) = 0
    
    // Main Textures
    _MainTextures ("'SpeedTree Textures' {Section:{126, 41, 41}}", Float) = 0
    [LM_Albedo] [LM_Transparency] 
    _Color ("'Tint' {}", Color) = (1,1,1,1)	
    [LM_MasterTilingOffset] [LM_Albedo] 
    _MainTex ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}, Controls:False}", 2D) = "white" {}
    _DetailTex ("'Detail(RGB) Opacity(A)' {Visualize:{RGB}, Controls:False}", 2D) = "black" {}
    [Toggle(EFFECT_BUMP)]
    _HasBumpMap ("'Normals?' {Toggle:{On:{}, Off:{_BumpMap,_DetailNormalMap}}}", Float) = 1
    [LM_NormalMap]
    _BumpMap ("'Normals' {Visualize:{NRM}, Controls:False}", 2D) = "bump" {}
    _DetailNormalMap ("'Detail Normals' {Visualize:{NRM}, Controls:False}", 2D) = "bump" {}
    [Toggle(EFFECT_HUE_VARIATION)]
    _HasHueVariation ("'Hue Variation?' {Toggle:{On:{}, Off:{_HueVariation}}}", Float) = 1
    _HueVariation ("'Hue Variation' {}", Color) = (1.0,0.5,0.0,0.1)

    // Main Physical Properties
    _MainPhysicalProperties ("'SpeedTree Physical Properties' {Section:{126, 66, 41}}", Float) = 0
    _Specularity ("'Specularity' {Min:0, Max:1}", Float) = 1
    _SpecularTint ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
    _Roughness ("'Roughness' {Min:0, Max:1}", Float) = 0.9
    _Occlusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
    _BumpScale ("'Normal Strength' {}", Float) = 1
        
    // Transmission Properties
    _TransmissionProperties ("'Transmission' {Section:{126, 118, 41}}", Float) = 0
    _TransTex ("'Transmission(G)' {Visualize:{RGB}, Parent:_MainTex}", 2D) = "white" {}
    [Gamma]
    _TransScale ("'Weight' {Min:0, Max:1}", Float) = 1
    
    // Parallax Properties
    [Toggle(_PARALLAX_ON)]
    _ParallaxT ("'Parallax' {Feature:{109, 126, 41}}", Float) = 0
    [KeywordEnum(Parallax, POM)]
    _BumpMode ("'Mode' {Dropdown:{Parallax:{_MinSamples, _MaxSamples}, POM:{}}}", Float) = 0
    _ParallaxMap ("'Heightmap(G)' {Visualize:{G}, Parent:_MainTex}", 2D) = "black" {}
    _Parallax ("'Height' {Min:0, Max:0.08}", Float) = 0.02
    _MinSamples ("'Min Samples' {Min:1}", Float) = 4
    _MaxSamples ("'Max Samples' {Min:1}", Float) = 20
        
    // Team Color Properties
    [Toggle(_TEAMCOLOR_ON)] 
    _TeamColor ("'Team Color' {Feature:{41, 126, 50}}", Float) = 0
    _TeamColorMaskMap ("'Masks(RGBA)' {Visualize:{R, G, B, A}, Parent:_MainTex}", 2D) = "black" {}
    _TeamColorMasksAsTint ("'Masks as Tint?' {Toggle:{On:{_TeamColorMasks, _TeamColor0, _TeamColor1, _TeamColor2, _TeamColor3}, Off:{}}}", Float) = 0
    _TeamColorMasks ("'Mask' {Vector:Mask}", Vector) = (1,1,1,0)
    _TeamColor0 ("'Tint R' {}", Color) = (1,0,0)
    _TeamColor1 ("'Tint G' {}", Color) = (0,1,0)
    _TeamColor2 ("'Tint B' {}", Color) = (0,0,1)
    _TeamColor3 ("'Tint A' {}", Color) = (0.5,0.5,0.5)
    
    // Decal Properties 
    [Toggle(_DECAL_ON)] 
    _Decal ("'Decal' {Feature:{41, 126, 75}}", Float) = 0	
    _DecalColor ("'Tint' {}", Color) = (1,1,1,1)
    _DecalTex ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "black" {} 
    _DecalTexUV ("UV Set", Float) = 0
    _DecalWeight ("'Weight' {Min:0, Max:1}", Float) = 1
    _DecalSpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
    _DecalAlphaVertexTint ("'Vertex Alpha Tint' {Min:0, Max:1}", Float) = 0

    // Emission Properties 
    [Toggle(_EMISSION)] 
    _Emission ("'Emission' {Feature:{41, 126, 101}}", Float) = 0
    [LM_Emission] 
    [HDR]
    _EmissionColor ("'Tint' {}", Color) = (1,1,1)
    [LM_Emission] 
    _EmissionMap ("'Mask(RGB)' {Visualize:{RGB}, Parent:_MainTex}", 2D) = "white" {}
    _IncandescenceMap ("'Effect(RGB)' {Visualize:{RGB}}", 2D) = "white" {} 
    _IncandescenceMapVelocity ("Scroll", Vector) = (0,0,0,0) 
    _IncandescenceMapUV ("UV Set", Float) = 0
    [Gamma]
    _EmissionWeight ("'Weight' {Min:0, Max:1}", Float) = 1

    // Rim Emission Properties 
    [Toggle(_RIM_ON)] 
    _Rim ("'Rim Emission' {Feature:{41, 125, 126}}", Float) = 0
    [HDR]
    _RimColor ("'Tint' {}", Color) = (1,1,1)
    _RimTex ("'Effect(RGB)' {Visualize:{RGB}}", 2D) = "white" {}
    _RimTexVelocity ("Scroll", Vector) = (0,0,0,0) 
    _RimTexUV ("UV Set", Float) = 0
    [Gamma]
    _RimWeight ("'Weight' {Min:0, Max:1}", Float) = 1
    [Gamma]
    _RimBias ("'Fill' {Min:0, Max:1}", Float) = 0
    _RimPower ("'Falloff' {Min:0.01}", Float) = 4

    // Dissolve Properties 
    [Toggle(_DISSOLVE_ON)] 
    _Dissolve ("'Dissolve' {Feature:{41, 100, 126}}", Float) = 0
    [HDR]
    _DissolveGlowColor ("'Glow Tint' {}", Color) = (1,1,1,1)
    _DissolveTex ("'Glow Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "white" {} 
    _DissolveTexUV ("UV Set", Float) = 0
    _DissolveCutoff ("'Cutoff' {Min:0, Max:1}", Float) = 0
    [Gamma]
    _DissolveGlowWeight ("'Glow Weight' {Min:0, Max:1}", Float) = 1
    _DissolveEdgeWidth ("'Glow Width' {Min:0, Max:1}", Float) = 0.01
}

SubShader {
    Tags {
        "Queue" = "Geometry"
        "IgnoreProjector" = "True"
        "RenderType" = "Opaque"
        "DisableBatching" = "LODFading"
    }
    LOD 400

    Pass {
        Name "FORWARD" 
        Tags { "LightMode" = "ForwardBase" }

        Cull [_Cull]

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles
        
        #pragma multi_compile __ LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
        #pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_MESH
        #pragma shader_feature EFFECT_BUMP
        #pragma shader_feature EFFECT_HUE_VARIATION
        #pragma shader_feature _PARALLAX_ON
        #pragma shader_feature _BUMPMODE_POM
        #pragma shader_feature _TEAMCOLOR_ON
        #pragma shader_feature _DECAL_ON
        #pragma shader_feature _EMISSION
        #pragma shader_feature _RIM_ON
        #pragma shader_feature _DISSOLVE_ON
        
        #pragma multi_compile_fwdbase
        #pragma multi_compile_fog
        //////#pragma multi_compile_instancing
            
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_FORWARDBASE
        
        #include "Assets/Alloy/Shaders/Definitions/SpeedTree.cginc"
        #include "Assets/Alloy/Shaders/Passes/ForwardBase.cginc"

        ENDCG
    }
    
    Pass {
        Name "FORWARD_DELTA"
        Tags { "LightMode" = "ForwardAdd" }
        
        Blend One One
        ZWrite Off
        Cull [_Cull]

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles
        
        #pragma multi_compile __ LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
        #pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_MESH
        #pragma shader_feature EFFECT_BUMP
        #pragma shader_feature EFFECT_HUE_VARIATION
        #pragma shader_feature _PARALLAX_ON
        #pragma shader_feature _BUMPMODE_POM
        #pragma shader_feature _TEAMCOLOR_ON
        #pragma shader_feature _DECAL_ON
        #pragma shader_feature _DISSOLVE_ON
        
        #pragma multi_compile_fwdadd_fullshadows
        #pragma multi_compile_fog
        //////#pragma multi_compile_instancing
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader

        #define UNITY_PASS_FORWARDADD

        #include "Assets/Alloy/Shaders/Definitions/SpeedTree.cginc"
        #include "Assets/Alloy/Shaders/Passes/ForwardAdd.cginc"

        ENDCG
    }
    
    Pass {
        Name "SHADOWCASTER"
        Tags { "LightMode" = "ShadowCaster" }
        
        Cull [_Cull]

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles

        #pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_MESH
        #pragma shader_feature _DISSOLVE_ON
        
        #pragma multi_compile_shadowcaster
        //////#pragma multi_compile_instancing

        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_SHADOWCASTER
        
        #include "Assets/Alloy/Shaders/Definitions/SpeedTree.cginc"
        #include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

        ENDCG
    }
    
    Pass {
        Name "DEFERRED"
        Tags { "LightMode" = "Deferred" }

        Cull [_Cull]

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt gles
        
        #pragma multi_compile __ LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
        #pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_MESH
        #pragma shader_feature EFFECT_BUMP
        #pragma shader_feature EFFECT_HUE_VARIATION
        #pragma shader_feature _PARALLAX_ON
        #pragma shader_feature _BUMPMODE_POM
        #pragma shader_feature _TEAMCOLOR_ON
        #pragma shader_feature _DECAL_ON
        #pragma shader_feature _EMISSION
        #pragma shader_feature _RIM_ON
        #pragma shader_feature _DISSOLVE_ON
        
        #pragma multi_compile ___ UNITY_HDR_ON
        #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
        #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
        #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
        //////#pragma multi_compile_instancing
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_DEFERRED
        
        #include "Assets/Alloy/Shaders/Definitions/SpeedTree.cginc"
        #include "Assets/Alloy/Shaders/Passes/Deferred.cginc"

        ENDCG
    }
    
    Pass {
        Name "Meta"
        Tags { "LightMode" = "Meta" }

        Cull Off

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt gles
        
        #pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_MESH
        #pragma shader_feature _TEAMCOLOR_ON
        #pragma shader_feature _DECAL_ON
        #pragma shader_feature _EMISSION

        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_META
        
        #include "Assets/Alloy/Shaders/Definitions/SpeedTree.cginc"
        #include "Assets/Alloy/Shaders/Passes/Meta.cginc"

        ENDCG
    }
}

FallBack "VertexLit"
CustomEditor "AlloyFieldBasedEditor"
}
