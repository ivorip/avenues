// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using Alloy;
using UnityEditor;
using PropType = UnityEditor.MaterialProperty.PropType;

static class AlloySceneDrawer {
	private static Dictionary<AlloyInspectorBase, MaterialEditor> s_inspectorKeeper = new Dictionary<AlloyInspectorBase, MaterialEditor>();
	static private List<AlloyInspectorBase> s_removekeys = new List<AlloyInspectorBase>();


	static AlloySceneDrawer() {
		EditorApplication.update += Update;

	}


	private static void Update() {
		var keys = s_inspectorKeeper.Keys;
		s_removekeys.Clear();


		foreach (var key in keys) {
			if (s_inspectorKeeper[key] != null) {
				continue;
			}

			key.OnAlloyShaderDisable();
			s_removekeys.Add(key);
		}

		foreach (var key in s_removekeys) {
			s_inspectorKeeper.Remove(key);
		}
	}

	public static void Register(AlloyInspectorBase inspector, MaterialEditor keeper) {
		if (!s_inspectorKeeper.ContainsKey(inspector)) {
			s_inspectorKeeper.Add(inspector, keeper);
		}
	}
}

public class AlloyInspectorBase : ShaderGUI {

	public MaterialEditor MatEditor;

	protected AlloyTabGroup TabGroup;
	private Dictionary<string, SerializedProperty> m_properties;

	private Shader m_oldShader;

	protected Dictionary<string, MaterialProperty> MaterialPropNames { get; private set; }
	protected MaterialProperty[] MaterialProperties { get; private set; }


	private Shader m_prevShader;
	private bool m_inited;


	public Object[] Targets {
		get { return MatEditor.targets; }
	}

	public Material Target {
		get { return (Material)MatEditor.target; }
	}

	public SerializedObject SerializedObject {
		get { return MatEditor.serializedObject; }
	}

	protected int MatInst {
		get {
			if (Selection.objects.Length == 1 && Selection.activeGameObject != null) {
				var sharedMaterials = Selection.activeGameObject.GetComponent<Renderer>().sharedMaterials;

				if (sharedMaterials != null) {
					return ArrayUtility.IndexOf(sharedMaterials, Target);
				}
			}

			return 0;
		}
	}

	public void OnEnable() {
		if (HasMutlipleShaders()) {
			return;
		}

		if (Target != null) {
			var ns = Target.shader;
			m_oldShader = ns;
		}

		TabGroup = AlloyTabGroup.GetTabGroup();
		m_properties = new Dictionary<string, SerializedProperty>();

		InitMaterialProps();

		if (Targets.Length > 1) {
			if (MaterialsAreMismatched()) {
				foreach (var target in Targets) {
					ClearMaterialCrum((Material)target);
				}

				IsValid = false;
				return;
			}
		}



		InitAllProps();

		SceneView.onSceneGUIDelegate += OnAlloySceneGUI;
		OnAlloyShaderEnable();
	}

	private bool HasMutlipleShaders() {
		if (MatEditor.targets.Length > 1) {

			return Targets.Any(o => {
				var objMat = o as Material;
				return objMat != null && (Target != null && objMat.shader != Target.shader);
			});
		}

		return false;
	}

	private void OnInspectorGUI() {
		if (HasMutlipleShaders()) {
			EditorGUILayout.HelpBox("Can't edit materials with different shaders!", MessageType.Warning);
			return;
		}


		SerializedObject.Update();

		GUILayout.Space(10.0f);
		if (MatEditor.isVisible) {
			OnAlloyShaderGUI();
		}

		SerializedObject.ApplyModifiedProperties();
	}

	private void InitAllProps() {

		m_properties.Clear();
		string prefix = GetTypeName(PropType.Vector) + "_";
		m_properties.Add(prefix + "ShaderKeywords", SerializedObject.FindProperty("m_ShaderKeywords"));

		prefix = GetTypeName(PropType.Float) + "_";
		m_properties.Add(prefix + "CustomRenderQueue", SerializedObject.FindProperty("m_CustomRenderQueue"));

		var textures = SerializedObject.FindProperty("m_SavedProperties.m_TexEnvs");
		AddPropsFromArray(PropType.Texture, textures);

		var floats = SerializedObject.FindProperty("m_SavedProperties.m_Floats");
		AddPropsFromArray(PropType.Float, floats);

		var colors = SerializedObject.FindProperty("m_SavedProperties.m_Colors");
		AddPropsFromArray(PropType.Color, colors);
	}

	private void InitMaterialProps() {
		MaterialProperties = MaterialEditor.GetMaterialProperties(Targets);
		MaterialPropNames = new Dictionary<string, MaterialProperty>();

		for (int i = 0; i < MaterialProperties.Length; ++i) {
			MaterialPropNames.Add(MaterialProperties[i].name, MaterialProperties[i]);
		}
	}

	protected virtual void OnAlloyShaderGUI() { }
	protected virtual void OnAlloyShaderEnable() { }

	private string GetPropertyName(PropType type, string varName) {
		var typeName = GetTypeName(type);
		return typeName + "_" + varName;
	}

	private static string GetTypeName(PropType type) {
		string typeName = "";

		switch (type) {
			case PropType.Color:
				typeName = "color";
				break;

			case PropType.Range:
			case PropType.Float:
				typeName = "float";
				break;

			case PropType.Texture:
				typeName = "tex";
				break;

			case PropType.Vector:
				typeName = "color";
				break;
		}

		return typeName;
	}

	//base API functions
	public SerializedProperty GetProperty(PropType type, string varName) {
		string prop = GetPropertyName(type, varName);


		if (!m_properties.ContainsKey(prop)) {

			if (MaterialPropNames.ContainsKey(varName)) {
				IsValid = false;
			}

			return null;
		}
		return m_properties[prop];
	}

	public bool IsValid = true;

	void ClearMaterialCrum(Material mat) {

		var so = new SerializedObject(mat);

		so.Update();

		var textures = so.FindProperty("m_SavedProperties.m_TexEnvs");
		ClearMaterialArray(PropType.Texture, textures);

		var floats = so.FindProperty("m_SavedProperties.m_Floats");
		ClearMaterialArray(PropType.Float, floats);

		var colors = so.FindProperty("m_SavedProperties.m_Colors");
		ClearMaterialArray(PropType.Color, colors);
		so.ApplyModifiedProperties();

		so.Dispose();

	}


	void ClearMaterialArray(PropType type, SerializedProperty props) {
		for (int i = 0; i < props.arraySize; ++i) {
			var prop = props.GetArrayElementAtIndex(i);
			var nameProp = prop.FindPropertyRelative("first.name");
			string propName = nameProp.stringValue;

			if (!MaterialPropNames.ContainsKey(propName) || MaterialPropNames[propName].type != type) {
				props.DeleteArrayElementAtIndex(i);
				--i;
			}
		}

		MatEditor.OnEnable();
	}

	private bool MaterialsAreMismatched() {
		var textures = SerializedObject.FindProperty("m_SavedProperties.m_TexEnvs");
		if (PropsInArrayMismatched(textures)) {
			return true;
		}

		var floats = SerializedObject.FindProperty("m_SavedProperties.m_Floats");
		if (PropsInArrayMismatched(floats)) {
			return true;
		}

		var colors = SerializedObject.FindProperty("m_SavedProperties.m_Colors");
		if (PropsInArrayMismatched(colors)) {
			return true;
		}

		return false;
	}


	private bool PropsInArrayMismatched(SerializedProperty props) {
		string original = props.propertyPath;

		props.Next(true);
		props.Next(true);
		props.Next(true);

		//some weird unity behaviour where it collapses the array 
		if (!props.propertyPath.Contains(original)) {
			return true;
		}

		do {
			var nameProp = props.FindPropertyRelative("first.name");

			if (nameProp.hasMultipleDifferentValues) {
				return true;
			}
		} while (props.NextVisible(false) && props.propertyPath.Contains(original));



		return false;
	}


	private void AddPropsFromArray(PropType type, SerializedProperty props) {
		string original = props.propertyPath;

		props.Next(true);
		props.Next(true);
		props.Next(true);

		do {
			var valueProp = props.FindPropertyRelative("second");
			var nameProp = props.FindPropertyRelative("first.name");



			string propName = nameProp.stringValue;

			AddProperty(propName, type, valueProp);
		} while (props.NextVisible(false) && props.propertyPath.Contains(original));
	}


	private void AddProperty(string propName, PropType type, SerializedProperty prop) {
		string prefix = GetTypeName(type) + "_";

		if (MaterialPropNames.ContainsKey(propName)
			&& (MaterialPropNames[propName].type == type
				|| (MaterialPropNames[propName].type == PropType.Vector && type == PropType.Color))) {
			m_properties.Add(prefix + propName, prop);
		}
	}

	private GUIContent GetDispName(string displayName, string varName) {
		if (string.IsNullOrEmpty(displayName)) {
			return new GUIContent(ObjectNames.NicifyVariableName(varName));
		}

		return new GUIContent(displayName);
	}

	public void MaterialPropertyField(string varName, string displayName, float dropWidth) {
		var matProp = MaterialEditor.GetMaterialProperty(Targets, varName);

		float old = EditorGUIUtility.labelWidth;
		EditorGUIUtility.labelWidth = Screen.width - dropWidth - 20.0f;

		MatEditor.ShaderProperty(matProp, ObjectNames.NicifyVariableName(displayName));

		EditorGUIUtility.labelWidth = old;
	}

	public void PropField(PropType type, string varName, string displayName,
		params GUILayoutOption[] options) {
		SerializedProperty prop = GetProperty(type, varName);

		if (prop != null) {
			EditorGUILayout.PropertyField(prop, GetDispName(displayName, varName), true, options);
		}
	}

	public virtual void OnAlloySceneGUI(SceneView sceneView) { }

	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
		MatEditor = materialEditor;
		IsValid = true;

		if (!m_inited) {
			AlloySceneDrawer.Register(this, MatEditor);
			OnEnable();
		}

		if (!IsValid) {
			EditorGUILayout.LabelField("There's a problem with the inspector. Reselect the material to fix");
			EditorApplication.delayCall += () => MatEditor.Repaint();
			return;
		}

		if (Target != null) {
			var ns = Target.shader;

			if (ns != m_oldShader) {
				EditorApplication.delayCall += OnEnable;
				MatEditor.Repaint();

				return;
			}
		}

		OnInspectorGUI();

		if (GUI.changed) {
			MaterialEditor.ApplyMaterialPropertyDrawers(Targets);
		}

		m_inited = true;
	}

	public virtual void OnAlloyShaderDisable() {
		SceneView.onSceneGUIDelegate -= OnAlloySceneGUI;
	}
}
