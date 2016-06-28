// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System;
using System.Collections.Generic;
using System.ComponentModel.Design;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEngine;

[CustomEditor(typeof(Light))]
[CanEditMultipleObjects]
public class AlloyLightEditor : Editor
{
    private Editor m_editor;
    private Editor m_areaEditor;

    private bool m_hasAreaComponent;
    private MethodInfo m_onScene;
    
    private Dictionary<string, FieldInfo> m_fieldCache = new Dictionary<string, FieldInfo>();
    private Dictionary<string, MethodInfo> m_methodCache = new Dictionary<string, MethodInfo>();
    
    private Type GetTypeGlobal(string typeName) {
        foreach (Assembly a in AppDomain.CurrentDomain.GetAssemblies()) {
            foreach (Type t in a.GetTypes()) {
                if (t.Name == typeName) {
                    return t;
                }
            }
        }
        
        return null;
    }
    
    private void CallEditorFunc(string funcName, params object[] args) {
        MethodInfo mi;

        if (!m_methodCache.TryGetValue(funcName, out mi)) {
            mi = m_editor.GetType().GetMethod(funcName, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            m_methodCache[funcName] = mi;
        }

        mi.Invoke(m_editor, args);
    }
    
    private T GetVal<T>(string valName) {
        FieldInfo fi;

        if (!m_fieldCache.TryGetValue(valName, out fi)) {
            fi = m_editor.GetType().GetField(valName, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            m_fieldCache[valName] = fi;
        }

        return (T)fi.GetValue(m_editor);
    }
    
    private GUIContent GetTextContent(string content) {
        MethodInfo mi;

        if (!m_methodCache.TryGetValue("TextContent", out mi)) {
            mi = typeof(EditorGUIUtility).GetMethod("TextContent", BindingFlags.Static | BindingFlags.NonPublic);
            m_methodCache["TextContent"] = mi;
        }

        return (GUIContent)mi.Invoke(null, new object[] { content });
    }
    
    private T GetStaticVal<T>(string valName) {
        FieldInfo fi;

        if (!m_fieldCache.TryGetValue(valName, out fi)) {
            fi = m_editor.GetType().GetField(valName, BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            m_fieldCache[valName] = fi;
        }

        return (T)fi.GetValue(null);
    }
    
    private T GetStlyeVal<T>(string valName) {
        var fi = GetStyleField();
        var styles = fi.GetValue(null);
        
        if (!m_fieldCache.TryGetValue(valName, out fi)) {
            fi = styles.GetType().GetField(valName, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            m_fieldCache[valName] = fi;
        }

        return (T)fi.GetValue(styles);
    }

    private FieldInfo GetStyleField() {
        FieldInfo fi;

        if (!m_fieldCache.TryGetValue("s_Styles", out fi)) {
            fi = m_editor.GetType().GetField("s_Styles", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            m_fieldCache["s_Styles"] = fi;
        }

        return fi;
    }
    
    private void OnEnable() {
        m_editor = CreateEditor(targets, GetTypeGlobal("LightEditor"));
        m_onScene = m_editor.GetType().GetMethod("OnSceneGUI", BindingFlags.Instance | BindingFlags.NonPublic);
        m_hasAreaComponent = targets.All(o => ((Light) o).GetComponent<AlloyAreaLight>() != null);
        
        if (m_hasAreaComponent) {
            RebindAreaLights();
        }

        GetStyleField().SetValue(null, Activator.CreateInstance(m_editor.GetType().GetNestedType("Styles", BindingFlags.Instance | BindingFlags.NonPublic)));
        UpdateAreaEditor();

        Undo.undoRedoPerformed += UndoRedoPerformed;
    }
    
    private void UndoRedoPerformed() {
        foreach (Light light in targets) {
            var area = light.GetComponent<AlloyAreaLight>();

            if (area != null) {
                area.UpdateBinding();
            }
        }
    }

    private void OnDisable() {
        Undo.undoRedoPerformed -= UndoRedoPerformed;
        
        DestroyImmediate(m_editor);
        
        if (m_areaEditor != null) {
            DestroyImmediate(m_areaEditor);
        }
    }
    
    private void UpdateAreaEditor() {
        if (m_hasAreaComponent) {
            if (m_areaEditor != null) {
                DestroyImmediate(m_areaEditor);
            }
            
            m_areaEditor = CreateEditor(targets.Select(o => ((Light) o).GetComponent<AlloyAreaLight>()).ToArray());
        }
    }

    private void OnSceneGUI() {
        m_onScene.Invoke(m_editor, null);
    }
    
    public override void OnInspectorGUI() {
        m_editor.serializedObject.Update();

        if (m_hasAreaComponent) {
            m_areaEditor.serializedObject.Update();
        }
        
        CallEditorFunc("UpdateShowOptions", false);
        
        EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_Type"));
        
        if (EditorGUILayout.BeginFadeGroup(1f - GetVal<AnimBool>("m_ShowAreaOptions").faded)) {
            EditorGUILayout.IntPopup(GetVal<SerializedProperty>("m_Lightmapping"), GetStlyeVal<GUIContent[]>("LightmappingModes"),
                GetStlyeVal<int[]>("LightmappingModeValues"), GetStlyeVal<GUIContent>("LightmappingModeLabel"));
            
            if (EditorGUILayout.BeginFadeGroup(GetVal<AnimBool>("m_ShowBakingWarning").faded))
                EditorGUILayout.HelpBox(GetTextContent("Enable Baked GI from Lighting window to use Baked or Mixed.").text, MessageType.Warning, false);
            
            EditorGUILayout.EndFadeGroup();
        }

        EditorGUILayout.EndFadeGroup();
        EditorGUILayout.Space();
        
        float num = !GetVal<AnimBool>("m_ShowDirOptions").isAnimating || !GetVal<AnimBool>("m_ShowAreaOptions").isAnimating ||
                    !GetVal<AnimBool>("m_ShowDirOptions").target && !GetVal<AnimBool>("m_ShowAreaOptions").target
            ? 1f - Mathf.Max(GetVal<AnimBool>("m_ShowDirOptions").faded, GetVal<AnimBool>("m_ShowAreaOptions").faded)
            : 0.0f;

        EditorGUILayout.EndFadeGroup();
        
        if (EditorGUILayout.BeginFadeGroup(num))
            EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_Range"));
        
        EditorGUILayout.EndFadeGroup();
        
        if (EditorGUILayout.BeginFadeGroup(GetVal<AnimBool>("m_ShowSpotOptions").faded))
            EditorGUILayout.Slider(GetVal<SerializedProperty>("m_SpotAngle"), 1f, 179f);
        
        EditorGUILayout.EndFadeGroup();
        
        if (EditorGUILayout.BeginFadeGroup(GetVal<AnimBool>("m_ShowAreaOptions").faded)) {
            EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_AreaSizeX"), new GUIContent("Width"));
            EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_AreaSizeY"), new GUIContent("Height"));
        }
        
        EditorGUILayout.EndFadeGroup();
        
        ColorAreaField();
        ColorIntensityField();
        
        EditorGUILayout.Slider(GetVal<SerializedProperty>("m_BounceIntensity"), 0.0f, 8f,
            GetStlyeVal<GUIContent>("LightBounceIntensity"));
        
        if (EditorGUILayout.BeginFadeGroup(GetVal<AnimBool>("m_ShowIndirectWarning").faded))
            EditorGUILayout.HelpBox(
                GetTextContent("Currently realtime indirect bounce light shadowing for spot and point lights is not supported.")
                    .text, MessageType.Warning, false);


        EditorGUILayout.EndFadeGroup();
        CallEditorFunc("ShadowsGUI");
        
        if (EditorGUILayout.BeginFadeGroup(GetVal<AnimBool>("m_ShowRuntimeOptions").faded))
            EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_Cookie"));

        EditorGUILayout.EndFadeGroup();

        if (EditorGUILayout.BeginFadeGroup(GetVal<AnimBool>("m_ShowRuntimeOptions").faded *
                                           GetVal<AnimBool>("m_ShowDirOptions").faded))
            EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_CookieSize"));
        
        EditorGUILayout.EndFadeGroup();
        EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_Halo"));
        EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_Flare"));
        EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_RenderMode"));
        EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_CullingMask"));
        EditorGUILayout.Space();

        if (SceneView.lastActiveSceneView != null && !SceneView.lastActiveSceneView.m_SceneLighting)
            EditorGUILayout.HelpBox(
                GetTextContent("One of your scene views has lighting disabled, please keep this in mind when editing lighting.")
                    .text, MessageType.Warning, false);

        m_editor.serializedObject.ApplyModifiedProperties();
        
        if (m_hasAreaComponent) {
            m_areaEditor.serializedObject.ApplyModifiedProperties();

            if (GUI.changed) {
                RebindAreaLights();
            }
        }

        bool anyMissing = false;

        foreach (Light light in targets) {
            // Skip Unity baked Area Lights.
            if (light.type != LightType.Area) {
                var area = light.GetComponent<AlloyAreaLight>();

                if (area == null) {
                    anyMissing = true;
                }
            }
        }

        if (anyMissing) {
            if (GUILayout.Button("Convert to area light", EditorStyles.toolbarButton)) {
                foreach (Light light in targets) {
                    light.gameObject.AddComponent<AlloyAreaLight>();
                }

                m_hasAreaComponent = true;
            }
        }
    }

    private void RebindAreaLights() {
        foreach (Light light in targets) {
            light.GetComponent<AlloyAreaLight>().UpdateBinding();
        }
    }

    private void ColorIntensityField() {
        if (!m_hasAreaComponent) {
            EditorGUILayout.PropertyField(GetVal<SerializedProperty>("m_Intensity"));
        }
        else {
            EditorGUI.BeginChangeCheck();
            var prop = m_areaEditor.serializedObject.FindProperty("m_intensity");

            EditorGUILayout.PropertyField(prop);
            GetVal<SerializedProperty>("m_Intensity").floatValue = 1.0f;

            //// Lumens.
            //if (targets.All(o => ((Light)o).type == LightType.Point || ((Light)o).type == LightType.Spot)) {
            //    var lumens = AlloyUtils.IntensityToLumens(prop.floatValue);

            //    lumens = EditorGUILayout.FloatField("Lumens", lumens);
            //    prop.floatValue = AlloyUtils.LumensToIntensity(lumens);
            //}

            if (EditorGUI.EndChangeCheck()) {
                prop.floatValue = Mathf.Max(0.0f, prop.floatValue);
            }
        }
    }

    private void ColorAreaField() {
        if (!m_hasAreaComponent) {
            var prop = GetVal<SerializedProperty>("m_Color");

            EditorGUILayout.PropertyField(prop);

            foreach (var o in targets) {
                var l = (Light) o;
                Color col = l.color;

                col.a = 0.0f;
                l.color = col;
            }
        }
        else {
            EditorGUILayout.PropertyField(m_areaEditor.serializedObject.FindProperty("m_color"));
        }
    }
}