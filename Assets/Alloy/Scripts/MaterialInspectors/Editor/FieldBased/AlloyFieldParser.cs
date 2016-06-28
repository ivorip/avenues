// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEditor.AnimatedValues;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using Alloy;
using UnityEditor;


//Generates drawers for a certain field
public abstract class AlloyFieldParser
{
    protected List<AlloyToken> Tokens;

    public bool HasSettings;
    public string DisplayName;

    protected MaterialProperty MaterialProperty;

    protected AlloyArgumentToken[] Arguments;

    protected AlloyFieldParser(MaterialProperty prop) {
        var lexer = new AlloyFieldLexer();
        Tokens = lexer.GenerateTokens(prop.displayName);

        if (Tokens.Count == 0) {
            Debug.LogError("No tokens found!");
            return;
        }

        MaterialProperty = prop;
        DisplayName = Tokens[0].Token;

        if (Tokens.Count <= 1) {
            return;
        }

        var settingsToken = Tokens[1] as AlloyCollectionToken;
        if (settingsToken == null) {
            return;
        }
        
        HasSettings = true;
        Arguments = settingsToken.SubTokens.OfType<AlloyArgumentToken>().ToArray();
    }



    public AlloyFieldDrawer GetDrawer(AlloyInspectorBase editor) {
        if (!HasSettings) {
            return null;
        }

        var drawer = GenerateDrawer(editor);
        if (drawer != null) {
            drawer.DisplayName = DisplayName;
        }

        return drawer;
    }

    protected abstract AlloyFieldDrawer GenerateDrawer(AlloyInspectorBase editor);
}


public class AlloyFieldDrawerArgs
{
    public AlloyFieldBasedEditor Editor;
    public AlloyTabGroup TabGroup;
    public Material[] Materials;

    public List<string> PropertiesSkip = new List<string>();

    public string CurrentTab;

    public int MatInst;
    public bool DoDraw = true;

    public List<AlloyTabAdd> TabsToAdd = new List<AlloyTabAdd>();

    public string[] AllTabNames;

    public Dictionary<string, AnimBool> OpenCloseAnim;
}

public class AlloyTabAdd {
    public string Name;
    public Color Color;

    public GenericMenu.MenuFunction Enable;
}

public abstract class AlloyFieldDrawer {
    protected MaterialProperty Property;
    public SerializedProperty Serialized;

    public string DisplayName;
    public abstract void Draw(AlloyFieldDrawerArgs args);


    public AlloyFieldDrawer(AlloyInspectorBase editor, MaterialProperty property) {
        Serialized = editor.GetProperty(property.type, property.name);
        Property = property;
    }

    protected void FloatFieldMin(string displayName, float min) {
        EditorGUI.BeginProperty(new Rect(), new GUIContent(), Serialized);
        
        EditorGUI.BeginChangeCheck();
        float newVal = EditorGUILayout.FloatField(displayName, Serialized.floatValue);


        if (EditorGUI.EndChangeCheck()) {
            Serialized.floatValue = Mathf.Max(newVal, min);
        }

        EditorGUI.EndProperty();
    }

    protected void FloatFieldMax(string displayName, float max) {
        EditorGUI.BeginProperty(new Rect(), new GUIContent(), Serialized);


        EditorGUI.BeginChangeCheck();
        float newVal = EditorGUILayout.FloatField(displayName, Serialized.floatValue);

        if (EditorGUI.EndChangeCheck()) {
            Serialized.floatValue = Mathf.Min(newVal, max);
        }

        EditorGUI.EndProperty();
    }

    protected void FloatFieldSlider(string displayName, float min, float max) {
        EditorGUI.BeginProperty(new Rect(), new GUIContent(), Serialized);
        
        EditorGUI.BeginChangeCheck();
        float newVal = EditorGUILayout.Slider(displayName, Serialized.floatValue, min, max, GUILayout.MinWidth(20.0f));

        if (EditorGUI.EndChangeCheck()) {
            Serialized.floatValue = newVal;
            Serialized.floatValue = Mathf.Clamp(Serialized.floatValue, min, max);
        }

        EditorGUI.EndProperty();
    }

    public void PropField(string displayName, params GUILayoutOption[] options) {
        if (Serialized != null) {
            EditorGUILayout.PropertyField(Serialized, new GUIContent(displayName), true, options);
        }
    }

    public void MaterialPropField(string displayName, AlloyFieldDrawerArgs args) {
        if (Property != null) {
            args.Editor.MatEditor.DefaultShaderProperty(Property, displayName);
        }
    }

    public virtual bool ShouldDraw(AlloyFieldDrawerArgs args) {
        return args.DoDraw && !args.PropertiesSkip.Contains(Property.name);
    }

    public virtual void OnSceneGUI(Material[] materials) {}
    public virtual void OnDisable() {}
}
