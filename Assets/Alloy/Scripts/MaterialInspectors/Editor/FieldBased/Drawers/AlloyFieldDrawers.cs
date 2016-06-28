// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System.Linq;
using UnityEditor;
using UnityEngine;

public class AlloyDefaultDrawer : AlloyFieldDrawer
{
    public override void Draw(AlloyFieldDrawerArgs args) {
        PropField(DisplayName);
    }

    public AlloyDefaultDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}


public class AlloyLightmapEmissionDrawer : AlloyFieldDrawer {
    public override void Draw(AlloyFieldDrawerArgs args) {
        args.Editor.MatEditor.LightmapEmissionProperty();
        
        foreach (var material in args.Materials) {
            // Setup lightmap emissive flags
            MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
            if ((flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) != 0) {
                flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                
            
                material.globalIlluminationFlags = flags;
            }
        }
    }

    public AlloyLightmapEmissionDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }

}

public class AlloyRenderingModeDrawer : AlloyDropdownDrawer
{
    public string RenderQueueOrderField;
    
    private enum RenderingMode
    {
        Opaque,
        Cutout,
        Fade,
        Transparent
    }
    
    protected override bool OnSetOption(int newOption, AlloyFieldDrawerArgs args) {
        base.OnSetOption(newOption, args);
        var newMode = (RenderingMode) newOption;
        bool setVal = true;

        if (!string.IsNullOrEmpty(RenderQueueOrderField)) {
            var custom = args.Editor.GetProperty(MaterialProperty.PropType.Float, RenderQueueOrderField);
            
            if (custom.floatValue > 0.5f) {
                setVal = false;
            }
        }
        
        foreach (var material in args.Materials) {
            switch (newMode) {
            case RenderingMode.Opaque:
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                
                if (setVal) {
                    material.renderQueue = -1;
                }
                break;
            case RenderingMode.Cutout:
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                
                material.DisableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.EnableKeyword("_ALPHATEST_ON");
                
                if (setVal) {
                    material.renderQueue = 2450;
                }
                break;
            case RenderingMode.Fade:
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.EnableKeyword("_ALPHABLEND_ON");
                
                if (setVal) {
                    material.renderQueue = 3000;
                }
                break;
            case RenderingMode.Transparent:
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                
                if (setVal) {
                    material.renderQueue = 3000;
                }
                break;
            }
            
            material.SetInt("_Mode", (int)newMode);
            EditorUtility.SetDirty(material);
        }
        
        Undo.RecordObjects(args.Materials, "Set blend mode");
        return true;
    }

    public AlloyRenderingModeDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}


public class AlloySpeedTreeGeometryTypeDrawer : AlloyDropdownDrawer
{	
    public string RenderQueueOrderField;

    private enum SpeedTreeGeometryType
    {
        Branch,
        BranchDetail,
        Frond,
        Leaf,
        Mesh,
    }

    private struct SpeedTreeKeywordSetting
    {
        public SpeedTreeGeometryType GeometryType;
        public string Keyword;
        public int RenderQueue;
    }

    private static readonly SpeedTreeKeywordSetting[] s_speedTreeKeywordSettings = {
        new SpeedTreeKeywordSetting()
        {
            GeometryType = SpeedTreeGeometryType.Branch,
            Keyword = "GEOM_TYPE_BRANCH",
            RenderQueue = -1
        },
        new SpeedTreeKeywordSetting()
        {
            GeometryType = SpeedTreeGeometryType.BranchDetail,
            Keyword = "GEOM_TYPE_BRANCH_DETAIL",
            RenderQueue = -1
        },
        new SpeedTreeKeywordSetting()
        {
            GeometryType = SpeedTreeGeometryType.Frond,
            Keyword = "GEOM_TYPE_FROND",
            RenderQueue = -1
        },
        new SpeedTreeKeywordSetting()
        {
            GeometryType = SpeedTreeGeometryType.Leaf,
            Keyword = "GEOM_TYPE_LEAF",
            RenderQueue = 2450
        },
        new SpeedTreeKeywordSetting()
        {
            GeometryType = SpeedTreeGeometryType.Mesh,
            Keyword = "GEOM_TYPE_MESH",
            RenderQueue = -1
        },
    };
    
    protected override bool OnSetOption(int newOption, AlloyFieldDrawerArgs args) {
        base.OnSetOption(newOption, args);
        SpeedTreeGeometryType newMode = (SpeedTreeGeometryType) newOption;
        bool setVal = true;

        if (!string.IsNullOrEmpty(RenderQueueOrderField)) {
            SerializedProperty custom = args.Editor.GetProperty(MaterialProperty.PropType.Float, RenderQueueOrderField);
            
            if (custom.floatValue > 0.5f) {
                setVal = false;
            }
        }
        
        for (int i = 0; i < args.Materials.Length; i++) {
            var material = args.Materials[i];

            for (int j = 0; j < s_speedTreeKeywordSettings.Length; j++) {
                SpeedTreeKeywordSetting setting = s_speedTreeKeywordSettings[j];
                string keyword = setting.Keyword;

                if (newMode != setting.GeometryType) {
                    material.DisableKeyword(keyword);
                }
                else {
                    material.EnableKeyword(keyword);

                    if (setVal) {
                        material.renderQueue = setting.RenderQueue;
                    }
                }
            }

            material.SetInt("_GeometryType", (int) newMode);
            EditorUtility.SetDirty(material);
        }

        Undo.RecordObjects(args.Materials, "Set geometry type");
        return true;
    }
    
    public AlloySpeedTreeGeometryTypeDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property)
    {
        // The original SpeedTree shader seemed to pick the dropdown value from
        // whichever keyword is already set on the material after import.

        // Note: Multi edit will override the _GeometryValue on other materials with whatever keywords the first material has set
        string[] keywords = editor.Target.shaderKeywords;
        property.floatValue = 0.0f;
        
        for (int i = 0; i < s_speedTreeKeywordSettings.Length; i++) {
            SpeedTreeKeywordSetting setting = s_speedTreeKeywordSettings[i];

            if (!keywords.Contains(setting.Keyword)) {
                continue;
            }

            property.floatValue = (int) setting.GeometryType;
            break;
        }
    }
}

public class AlloyDecalSortOrderDrawer : AlloyFieldDrawer {
    private const float PostAlphaTestQueue = 2450.0f + 1.0f;

    public override void Draw(AlloyFieldDrawerArgs args) {
        float sortOrder = Serialized.floatValue - PostAlphaTestQueue;

        // Snap to integers.
        EditorGUI.BeginChangeCheck();
        sortOrder = (int)EditorGUILayout.Slider(DisplayName, sortOrder, 0, 20, GUILayout.MinWidth(20.0f));

        if (EditorGUI.EndChangeCheck()) {
            Serialized.floatValue = sortOrder + PostAlphaTestQueue;

            foreach (var material in args.Materials) {
                material.renderQueue = (int)Serialized.floatValue;
            }
        }
    }

    public AlloyDecalSortOrderDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}

public class AlloyColorParser : AlloyFieldParser{
    protected override AlloyFieldDrawer GenerateDrawer(AlloyInspectorBase editor) {
        var ret = new AlloyColorDrawer(editor, MaterialProperty);
        return ret;
    }
    
    public AlloyColorParser(MaterialProperty field) : base(field) {
    }
}

public class AlloyColorDrawer : AlloyFieldDrawer {
    public override void Draw(AlloyFieldDrawerArgs args) {
        MaterialPropField(DisplayName, args);
    }

    public AlloyColorDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}
