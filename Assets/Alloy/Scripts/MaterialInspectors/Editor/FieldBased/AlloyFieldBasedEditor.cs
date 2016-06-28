// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;

using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.AnimatedValues;

[CanEditMultipleObjects]
public class AlloyFieldBasedEditor : AlloyInspectorBase
{
    private Dictionary<string, AnimBool> m_openCloseAnim;
    private Dictionary<MaterialProperty, AlloyFieldDrawer> m_propInfo;

    //private GenericMenu m_menu;
    private string[] m_allTabs;
    
    private void CloseTabNow(string toggleName) {
        GetProperty(MaterialProperty.PropType.Float, toggleName).floatValue = 0.0f;
        SerializedObject.ApplyModifiedProperties();
        MaterialEditor.ApplyMaterialPropertyDrawers(Targets);

        SceneView.lastActiveSceneView.Repaint();
    }

    public bool TabIsEnabled(string toggleName) {
        var prop = GetProperty(MaterialProperty.PropType.Float, toggleName);

        if (prop == null) {
            Debug.LogError("Can't find tab: " + toggleName);
            return false;
        }

        return !prop.hasMultipleDifferentValues && prop.floatValue > 0.5f;
    }

    public void EnableTab(string tab, string toggleName, int matInst) {
        m_openCloseAnim[toggleName].value = false;
        TabGroup.SetOpen(tab + matInst, true);

        GetProperty(MaterialProperty.PropType.Float, toggleName).floatValue = 1.0f;
        SerializedObject.ApplyModifiedProperties();
        MaterialEditor.ApplyMaterialPropertyDrawers(Targets);

        SceneView.lastActiveSceneView.Repaint();
    }
    
    public void DisableTab(string tab, string toggleName, int matInst) {
        if (TabGroup.IsOpen(tab + matInst)) {
            EditorApplication.delayCall += () => CloseTabNow(toggleName);
        }
        else {
            CloseTabNow(toggleName);
        }

        m_openCloseAnim[toggleName].target = false;
        TabGroup.SetOpen(tab + matInst, false);
    }

    protected override void OnAlloyShaderEnable() {
        m_openCloseAnim = new Dictionary<string, AnimBool>();
        m_propInfo = new Dictionary<MaterialProperty, AlloyFieldDrawer>();
        
        foreach (var property in MaterialProperties) {
            var drawer = AlloyFieldDrawerFactory.GetFieldDrawer(this, property);
            m_propInfo.Add(property, drawer);
        }

        var allTabs = new List<string>();

        foreach (var drawerProp in m_propInfo) {
            var drawer = drawerProp.Value;

            if (drawer is AlloyTabDrawer) {

                bool isOpenCur = TabGroup.IsOpen(drawer.DisplayName + MatInst);
                
                var anim = new AnimBool(isOpenCur) {speed = 6.0f, value = isOpenCur};
                m_openCloseAnim.Add(drawerProp.Key.name, anim);

                allTabs.Add(drawer.DisplayName);
            }


        }
        
        m_allTabs = allTabs.ToArray();
        //m_menu = new GenericMenu();
        Undo.undoRedoPerformed += OnUndo;
    }
    
    public override void OnAlloyShaderDisable() {
        base.OnAlloyShaderDisable();

        if (m_propInfo != null) {
            foreach (var drawer in m_propInfo) {
                if (drawer.Value != null) {
                    drawer.Value.OnDisable();
                }
            }

            m_propInfo.Clear();
        }
    }

    private void OnUndo() {
        OnAlloyShaderDisable();
    }
    
    protected override void OnAlloyShaderGUI() {
        var args = new AlloyFieldDrawerArgs() {
            Editor = this,
            Materials = Targets.Cast<Material>().ToArray(),
            PropertiesSkip = new List<string>(),
            MatInst = MatInst,
            TabGroup = TabGroup,
            AllTabNames = m_allTabs,
            OpenCloseAnim = m_openCloseAnim
        };

        foreach (var animBool in m_openCloseAnim) {
            if (animBool.Value.isAnimating) {
                MatEditor.Repaint();
            }
        }
        
        foreach (var kv in m_propInfo) {
            var drawer = kv.Value;

            if (drawer != null && drawer.ShouldDraw(args)) {
                drawer.Draw(args);
            }
        }
        
        if (!string.IsNullOrEmpty(args.CurrentTab)) {
            EditorGUILayout.EndFadeGroup();
        }
        
        GUILayout.Space(10.0f);
        AlloyEditor.DrawAddTabGUI(args.TabsToAdd);
    }
    
    public override void OnAlloySceneGUI(SceneView sceneView) {
        foreach (var drawer in m_propInfo) {
            if (drawer.Value == null) {
                continue;
            }

            drawer.Value.Serialized = GetProperty(drawer.Key.type, drawer.Key.name);
            drawer.Value.OnSceneGUI(Targets.Cast<Material>().ToArray());
        }
    }
}