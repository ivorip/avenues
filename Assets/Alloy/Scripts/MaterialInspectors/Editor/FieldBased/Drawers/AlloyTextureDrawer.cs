// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using Alloy;
using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEngine;

public class AlloyTextureFieldDrawer : AlloyFieldDrawer
{
    public enum TextureVisualizeMode
    {
        None,
        RGB,
        R,
        G,
        B,
        A,
        NRM
    }

    public string ParentTexture {
        get { return m_parentTexture; }
        set {
            m_parentTexture = value;
            m_hasParentTexture = !string.IsNullOrEmpty(value);
        }
    }

    public TextureVisualizeMode[] DisplayModes;
    public bool Controls = true;

    private SerializedProperty m_scale;
    private SerializedProperty m_offset;

    private SerializedProperty m_velocityProp;
    private SerializedProperty m_spinProp;
    private SerializedProperty m_uvProp;

    private string m_shaderVarName;
    private int m_inst;
    private string m_parentTexture = string.Empty;
    private bool m_hasParentTexture;

    private AlloyTabGroup m_tabGroup;

    private AnimBool m_tabOpen = new AnimBool(false);
    private bool m_firstDraw = true;


    private int m_vizIndex;

    private Material m_visualizeMat;
    private Renderer m_oldSelect;

    private static GUIContent[] s_uvModes = { new GUIContent("UV0"), new GUIContent("UV1") };

    private Material VisualizeMaterial {
        get {
            if (m_visualizeMat == null) {
                m_visualizeMat = new Material(Shader.Find("Hidden/Alloy Visualize")) { hideFlags = HideFlags.HideAndDontSave };
            }

            return m_visualizeMat;
        }
    }

    protected virtual string TextureProp {
        get { return "m_Texture"; }
    }


    private TextureVisualizeMode Mode {
        get { return m_vizIndex == 0 ? TextureVisualizeMode.None : DisplayModes[m_vizIndex - 1]; }
    }

    private string SaveName {
        get { return m_shaderVarName + m_inst; }
    }

    protected bool IsOpen {
        get { return m_tabGroup.IsOpen(SaveName); }
    }

    //Passed in by the base editor
    public AlloyTextureFieldDrawer(AlloyInspectorBase editor, MaterialProperty property)
        : base(editor, property) {
        m_tabGroup = AlloyTabGroup.GetTabGroup();
        m_tabOpen.speed = 4.0f;

        m_scale = Serialized.FindPropertyRelative("m_Scale");
        m_offset = Serialized.FindPropertyRelative("m_Offset");

        m_shaderVarName = Property.name;


        CacheTextureProps(editor, m_shaderVarName, out m_velocityProp, out m_spinProp, out m_uvProp);
    }

    public static void CacheTextureProps(AlloyInspectorBase editor,
        string shaderVarName,
        out SerializedProperty scrollProp,
        out SerializedProperty spinProp,
        out SerializedProperty uvProp) {
        string velName = shaderVarName + "Velocity";
        scrollProp = editor.GetProperty(MaterialProperty.PropType.Vector, velName);

        string spinName = shaderVarName + "Spin";
        spinProp = editor.GetProperty(MaterialProperty.PropType.Float, spinName);

        string uvName = shaderVarName + "UV";
        uvProp = editor.GetProperty(MaterialProperty.PropType.Float, uvName);
    }

    private void AdvanceMode() {
        m_vizIndex = (m_vizIndex + 1) % (DisplayModes.Length + 1);
    }

    private string GetVisualizeButtonText() {
        return Mode == TextureVisualizeMode.None ? "Visualize" : Mode.ToString();
    }

    private void TextureField(float size, SerializedProperty prop, AlloyFieldDrawerArgs args) {
        var rawRef = prop.objectReferenceValue;
        GUILayoutOption[] layout = new GUILayoutOption[2];

        if (rawRef == null
            && !prop.hasMultipleDifferentValues
            && (!IsOpen || m_hasParentTexture)) {

            layout[0] = GUILayout.Width(100.0f);
            layout[1] = GUILayout.Height(16.0f);
        }
        else {
            layout[0] = GUILayout.Width(size - 20.0f);
            layout[1] = GUILayout.Height((size - 20.0f) * 0.9f);
        }

        EditorGUI.BeginProperty(new Rect(), null, prop);
        EditorGUI.BeginChangeCheck();

        var tex = EditorGUILayout.ObjectField(rawRef, typeof(Texture), false, layout);

        if (EditorGUI.EndChangeCheck()) {
            prop.objectReferenceValue = tex;
        }

        EditorGUI.EndProperty();

    }

    private bool DrawWarningString(SerializedProperty texture) {
        //normal map warning
        if (DisplayModes == null) {
            return false;
        }

        if (ArrayUtility.Contains(DisplayModes, TextureVisualizeMode.NRM)) {
            if (texture.hasMultipleDifferentValues || texture.objectReferenceValue == null) {
                return false;
            }

            string path = AssetDatabase.GetAssetPath(texture.objectReferenceValue);

            if (!string.IsNullOrEmpty(path)) {
                var imp = AssetImporter.GetAtPath(path);
                var importer = imp as TextureImporter;

                if (importer != null && !importer.normalmap) {
                    //return "Texture not marked as normal map";

                    GUILayout.BeginHorizontal();
                    EditorGUILayout.HelpBox("Texture not marked as normal map", MessageType.Warning, true);

                    var rect = GUILayoutUtility.GetLastRect();

                    rect.xMin += rect.width / 2;

                    GUILayout.BeginVertical();

                    GUILayout.Space(14.0f);

                    if (GUILayout.Button("Fix now", EditorStyles.toolbarButton, GUILayout.Width(60.0f))) {
                        importer.textureType = TextureImporterType.Bump;
                        importer.normalmap = true;
                        AssetDatabase.ImportAsset(path);
                    }

                    GUILayout.EndVertical();

                    GUILayout.EndHorizontal();

                    return true;
                }
            }
        }

        return false;
    }

    private void DrawVisualizeButton() {
        if (DisplayModes != null && DisplayModes.Length > 0
            && Selection.activeGameObject && Selection.objects.Length == 1) {
            if (GUILayout.Button(GetVisualizeButtonText(), EditorStyles.toolbarButton, GUILayout.Width(70.0f))) {
                AdvanceMode();
                EditorApplication.delayCall += SceneView.RepaintAll;
            }
        }
    }



    private Vector4 GetTextureTransformation(Material material) {
        Vector2 offset;
        Vector2 scale;

        if (!m_hasParentTexture) {
            offset = m_offset.vector2Value;
            scale = m_scale.vector2Value;
        }
        else {
            offset = material.GetTextureOffset(m_parentTexture);
            scale = material.GetTextureScale(m_parentTexture);
        }

        return new Vector4(offset.x, offset.y, scale.x, scale.y);
    }


    public override void OnDisable() {
        if (Mode != TextureVisualizeMode.None) {
            if (m_oldSelect != null) {
                EditorUtility.SetSelectedWireframeHidden(m_oldSelect, false);
            }

            m_vizIndex = 0;
            Serialized = null;
        }
    }

    public override void OnSceneGUI(Material[] materials) {
        if (materials.Length > 1) {
            return;
        }

        var material = materials[0];

        if (Mode == TextureVisualizeMode.None || Selection.activeGameObject == null || Selection.objects.Length != 1) {
            if (m_oldSelect != null) {
                EditorUtility.SetSelectedWireframeHidden(m_oldSelect, false);
            }

            return;
        }

        if (Serialized == null) {
            return;
        }

        var texture = Serialized.FindPropertyRelative(TextureProp);
        var curTex = texture.objectReferenceValue as Texture;

        if (Mode == TextureVisualizeMode.None) {
            return;
        }

        var trans = GetTextureTransformation(material);
        var uvMode = 0.0f;
        var uvName = !m_hasParentTexture ? m_shaderVarName + "UV" : m_parentTexture + "UV";

        if (material.HasProperty(uvName)) {
            uvMode = material.GetFloat(uvName);
        }

        VisualizeMaterial.SetTexture("_MainTex", curTex);
        VisualizeMaterial.SetFloat("_Mode", (int)Mode);
        VisualizeMaterial.SetVector("_Trans", trans);
        VisualizeMaterial.SetFloat("_UV", uvMode);

        var target = Selection.activeGameObject.GetComponent<Renderer>();

        if (target != m_oldSelect && m_oldSelect != null) {
            EditorApplication.delayCall += SceneView.RepaintAll;
            EditorUtility.SetSelectedWireframeHidden(target, false);
            return;
        }

        m_oldSelect = target;

        Mesh mesh = null;
        var meshFilter = target.GetComponent<MeshFilter>();
        var meshRenderer = target.GetComponent<MeshRenderer>();

        if (meshFilter != null && meshRenderer != null) {
            mesh = meshFilter.sharedMesh;
        }

        if (mesh == null) {
            var skinnedMeshRenderer = target.GetComponent<SkinnedMeshRenderer>();

            if (skinnedMeshRenderer != null) {
                mesh = skinnedMeshRenderer.sharedMesh;
            }
        }

        if (mesh != null) {
            EditorUtility.SetSelectedWireframeHidden(target, true);

            Graphics.DrawMesh(mesh, target.localToWorldMatrix, VisualizeMaterial, 0, SceneView.currentDrawingSceneView.camera, m_inst);
            SceneView.currentDrawingSceneView.Repaint();
        }
        else {
            Debug.LogError("Game object does not have a mesh source.");
        }
    }

    public override void Draw(AlloyFieldDrawerArgs args) {
        m_inst = args.MatInst;

        if (m_firstDraw) {
            OnFirstDraw();
            m_firstDraw = false;
        }

        var texture = Serialized.FindPropertyRelative(TextureProp);
        var curTex = texture.objectReferenceValue as Texture;

        GUILayout.Space(9.0f);

        GUILayout.BeginHorizontal();

        EditorGUILayout.BeginVertical();

        float oldWidth = EditorGUIUtility.labelWidth;
        EditorGUIUtility.labelWidth = 80.0f;

        bool drewOpen = false;

        if (m_hasParentTexture || !Controls) {
            GUILayout.Label(DisplayName);
        } else {
            bool isOpen = m_tabGroup.Foldout(DisplayName, SaveName, GUILayout.Width(10.0f));
            m_tabOpen.target = isOpen;

            if (EditorGUILayout.BeginFadeGroup(m_tabOpen.faded)) {				
                drewOpen = true;				
                AlloyGUI.Vector2Field(m_scale, "Tiling");
                AlloyGUI.Vector2Field(m_offset, "Offset");
                DrawTextureControls(m_velocityProp, m_spinProp, m_uvProp);
            }

            EditorGUILayout.EndFadeGroup();
    
        }

        if ((EditorGUILayout.BeginFadeGroup(1.0f - m_tabOpen.faded)
                || !Controls)
            && curTex != null
            && !texture.hasMultipleDifferentValues) {

            if (!DrawWarningString(texture)) {
                var oldCol = GUI.color;
                GUI.color = EditorGUIUtility.isProSkin ? Color.gray : new Color(0.3f, 0.3f, 0.3f);

                string name = curTex.name;
                if (name.Length > 17) {
                    name = name.Substring(0, 14) + "..";
                }
                GUILayout.Label(name + " (" + curTex.width + "x" + curTex.height + ")", EditorStyles.whiteLabel);
                GUI.color = oldCol;
            }
        }

        EditorGUILayout.EndFadeGroup();

        if (curTex != null
            && (!m_hasParentTexture || Controls)
            && !texture.hasMultipleDifferentValues) {
            DrawVisualizeButton();
        }

        if (drewOpen) {
            EditorGUILayout.EndVertical();
            TextureField(Mathf.Lerp(74.0f, 100.0f, m_tabOpen.faded), texture, args);
        }
        else {
            GUILayout.EndVertical();

            GUILayout.FlexibleSpace();
            TextureField(74.0f, texture, args);
        }

        EditorGUIUtility.labelWidth = oldWidth;
        GUILayout.EndHorizontal();

        if (IsOpen) {
            GUILayout.Space(10.0f);
        }

        if (m_tabOpen.isAnimating) {
            args.Editor.MatEditor.Repaint();
        }
    }

    public static void DrawTextureControls(SerializedProperty scroll, SerializedProperty spinProp, SerializedProperty uvProp) {
        if (scroll != null) {
            AlloyGUI.Vector2Field(scroll, "Scroll");
        }

        float old = EditorGUIUtility.labelWidth;
        EditorGUIUtility.labelWidth = 75.0f;

        if (spinProp != null) {
            
            EditorGUI.BeginProperty(new Rect(), new GUIContent(), spinProp);
            EditorGUI.BeginChangeCheck();

            float spin = spinProp.floatValue * Mathf.Rad2Deg;
            spin = EditorGUILayout.FloatField(new GUIContent("Spin"), spin, GUILayout.Width(180.0f));

            if (EditorGUI.EndChangeCheck()) {
                spinProp.floatValue = spin * Mathf.Deg2Rad;
            }

            EditorGUI.EndProperty();
            
        }

        if (uvProp != null) {
            EditorGUI.BeginProperty(new Rect(), new GUIContent(), uvProp);
            EditorGUI.BeginChangeCheck();

            float newVal = EditorGUILayout.Popup(new GUIContent("UV Set"), (int)uvProp.floatValue, s_uvModes, GUILayout.Width(180.0f));

            if (EditorGUI.EndChangeCheck()) {
                uvProp.floatValue = newVal;
            }
        }

        EditorGUIUtility.labelWidth = old;
    }

    private void OnFirstDraw() {
        m_tabOpen.value = IsOpen;
    }
}
