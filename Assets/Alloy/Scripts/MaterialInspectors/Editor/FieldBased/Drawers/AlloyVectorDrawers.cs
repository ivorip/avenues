// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using Alloy;
using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEngine;
using UnityEngine.UI;

public class AlloyVectorParser : AlloyFieldParser
{
    protected override AlloyFieldDrawer GenerateDrawer(AlloyInspectorBase editor) {
        AlloyFieldDrawer ret = null;

        for (int i = 0; i < Arguments.Length; i++) {
            var argument = Arguments[i];

            var valProp = argument.ArgumentToken as AlloyValueToken;


            switch (argument.ArgumentName) {
                case "Vector":

                    if (valProp != null) {
                        ret = SetupVectorDrawer(editor, valProp, ret);
                    }
                break;
            }
        }

        if (ret == null) {
            ret = new AlloyVectorDrawer(editor, MaterialProperty);
            ((AlloyVectorDrawer)ret).Mode = AlloyVectorDrawer.VectorMode.Vector4;
        }


        return ret;
    }

    private AlloyFieldDrawer SetupVectorDrawer(AlloyInspectorBase editor, AlloyValueToken valProp,
        AlloyFieldDrawer ret) {
        if (valProp.ValueType == AlloyValueToken.ValueTypeEnum.String) {
            switch (valProp.StringValue) {
                case "Euler":
                    ret = new AlloyVectorDrawer(editor, MaterialProperty);
                    ((AlloyVectorDrawer) ret).Mode = AlloyVectorDrawer.VectorMode.Euler;
                    break;

                case "TexCoord":
                    ret = new AlloyTexCoordDrawer(editor, MaterialProperty);
                    break;

                case "Mask":
                    ret = new AlloyMaskDrawer(editor, MaterialProperty);
                    break;

                default:
                    Debug.LogError("Non supported vector property!");
                    break;
            }
        }
        else if (valProp.ValueType == AlloyValueToken.ValueTypeEnum.Float) {
            switch ((int) valProp.FloatValue) {
                case 2:
                    ret = new AlloyVectorDrawer(editor, MaterialProperty);
                    ((AlloyVectorDrawer) ret).Mode = AlloyVectorDrawer.VectorMode.Vector2;
                    break;

                case 3:
                    ret = new AlloyVectorDrawer(editor, MaterialProperty);
                    ((AlloyVectorDrawer) ret).Mode = AlloyVectorDrawer.VectorMode.Vector3;
                    break;

                case 4:
                    ret = new AlloyVectorDrawer(editor, MaterialProperty);
                    ((AlloyVectorDrawer) ret).Mode = AlloyVectorDrawer.VectorMode.Vector4;
                    break;

                default:
                    Debug.LogError("Non supported vector property!");
                    break;
            }
        }
        return ret;
    }

    public AlloyVectorParser(MaterialProperty field)
        : base(field) {
    }

}

public class AlloyVectorDrawer : AlloyFieldDrawer
{
    public enum VectorMode
    {
        Vector2,
        Vector3,
        Vector4,
        Euler
    }

    public VectorMode Mode = VectorMode.Vector4;

    public override void Draw(AlloyFieldDrawerArgs args) {
        Vector4 newVal = Vector4.zero;
        var label = new GUIContent(DisplayName);

        EditorGUI.BeginProperty(new Rect(), label, Serialized);
        EditorGUI.BeginChangeCheck();

        switch (Mode) {
            case VectorMode.Vector4:
                newVal = EditorGUILayout.Vector4Field(label.text, Serialized.colorValue);
                break;


            case VectorMode.Vector3:
                newVal = EditorGUILayout.Vector3Field(label.text, (Vector4)Serialized.colorValue);
                break;

            case VectorMode.Vector2:
                newVal = EditorGUILayout.Vector2Field(label.text, (Vector4)Serialized.colorValue);
                break;

            case VectorMode.Euler:
                var value =
                    (Vector4)args.Editor.GetProperty(MaterialProperty.PropType.Vector, Property.name + "EulerUI").colorValue;
                newVal = Quaternion.Euler(value) * Vector3.up;
                GUI.changed = true;
                break;
        }

        if (EditorGUI.EndChangeCheck()) {
            Serialized.colorValue = newVal;
        }

        EditorGUI.EndProperty();
    }

    public AlloyVectorDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}


public class AlloyTexCoordDrawer : AlloyFieldDrawer
{
    private string m_shaderVarName;
    private int m_inst;
    private AlloyTabGroup m_tabGroup;
    private AnimBool m_tabOpen = new AnimBool(false);

    private SerializedProperty m_scrollProp;
    private SerializedProperty m_spinProp;
    private SerializedProperty m_uvProp;


    private string SaveName {
        get { return m_shaderVarName + m_inst; }
    }

    public AlloyTexCoordDrawer(AlloyInspectorBase editor, MaterialProperty property)
        : base(editor, property) {

        m_shaderVarName = Property.name.Replace("_ST", "");
        m_tabGroup = AlloyTabGroup.GetTabGroup();

        m_tabOpen.value = m_tabGroup.IsOpen(SaveName);

        AlloyTextureFieldDrawer.CacheTextureProps(editor,
            m_shaderVarName,
            out m_scrollProp,
            out m_spinProp,
            out m_uvProp);
    }

    public override void Draw(AlloyFieldDrawerArgs args) {
        m_inst = args.MatInst;

        bool isOpen = m_tabGroup.Foldout(DisplayName, SaveName, GUILayout.Width(10.0f));
        m_tabOpen.target = isOpen;

        if (m_tabOpen.value) {
            EditorGUILayout.BeginFadeGroup(m_tabOpen.faded);
            AlloyGUI.Vector2Field(Serialized, "Tiling", true);
            AlloyGUI.Vector2Field(Serialized, "Offset", false);


            AlloyTextureFieldDrawer.DrawTextureControls(m_scrollProp, m_spinProp, m_uvProp);
            EditorGUILayout.EndFadeGroup();
        }

        if (m_tabOpen.isAnimating) {
            args.Editor.MatEditor.Repaint();
        }
    }
}



public class AlloyMaskDrawer : AlloyFieldDrawer {
    public AlloyMaskDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {



    }


    public override void Draw(AlloyFieldDrawerArgs args) {
        Vector4 newVal = Serialized.colorValue;
        var label = new GUIContent(DisplayName);


        EditorGUI.BeginProperty(new Rect(), label, Serialized);
        EditorGUI.BeginChangeCheck();


        
        GUILayout.BeginHorizontal();
        GUILayout.Label(label);


        newVal.x = GUILayout.Toggle(newVal.x > 0.5f, "R", EditorStyles.toolbarButton) ? 1.0f : 0.0f;
        newVal.y = GUILayout.Toggle(newVal.y > 0.5f, "G", EditorStyles.toolbarButton) ? 1.0f : 0.0f;
        newVal.z = GUILayout.Toggle(newVal.z > 0.5f, "B", EditorStyles.toolbarButton) ? 1.0f : 0.0f;
        newVal.w = GUILayout.Toggle(newVal.w > 0.5f, "A", EditorStyles.toolbarButton) ? 1.0f : 0.0f;
        GUILayout.EndHorizontal();


        if (EditorGUI.EndChangeCheck()) {
            Serialized.colorValue = newVal;
        }

        EditorGUI.EndProperty();
    }
}