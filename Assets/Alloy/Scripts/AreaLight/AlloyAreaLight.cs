// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/
#if UNITY_EDITOR
using UnityEditor;
#endif

using UnityEngine;
using UnityEngine.Serialization;

[RequireComponent(typeof(Light))]
[ExecuteInEditMode]
[AddComponentMenu("Alloy/Area Light")]
public class AlloyAreaLight : MonoBehaviour {
    private const float c_minimumLightSize = 0.00001f;

    [SerializeField] 
    private Color m_color = new Color(1.0f, 1.0f, 1.0f, 0.0f);

    [SerializeField] 
    private float m_intensity = 1.0f;

    [FormerlySerializedAs("m_size")]
    [SerializeField] 
    private float m_radius;

    [SerializeField]
    private float m_length;

    [SerializeField] 
    private bool m_hasSpecularHightlight = true;

    private Light m_light;
    private float m_lastRange;

    private Light Light {
        get
        {
            // Ensures that we have the light component, even if light is disabled.
            if (m_light == null)
                m_light = GetComponent<Light>();

            return m_light;
        }
    }

    public float Radius {
        get { return m_radius; }
        set {
            if (m_radius != value) {
                m_radius = value;
                UpdateBinding();
            }
        }
    }

    public float Length {
        get { return m_length; }
        set {
            if (m_length != value) {
                m_length = value;
                UpdateBinding();
            }
        }
    }

    public float Intensity {
        get { return m_intensity; }
        set {
            if (m_intensity != value) {
                m_intensity = value;
                
                UpdateBinding();
            }
        }
    }

    public float Lumens {
        get { 
            return AlloyUtils.IntensityToLumens(m_intensity); 
        }
        set {
            var newInstensity = AlloyUtils.LumensToIntensity(value);

            if (m_intensity != newInstensity) {
                m_intensity = newInstensity;

                UpdateBinding();
            }
        }
    }

    public Color Color {
        get { return m_color; }
        set {
            if (m_color != value) {
                m_color = value;
                
                UpdateBinding();
            }
        }
    }
    
    public bool HasSpecularHighlight {
        get { return m_hasSpecularHightlight; }
        set {
            if (m_hasSpecularHightlight != value) {
                m_hasSpecularHightlight = value;
                
                UpdateBinding();
            }
        }
    }

    private static Texture2D s_defaultSpot;

    [HideInInspector]
    public static Texture2D DefaultSpotLightCookie {
        get {
            if (s_defaultSpot == null) {
                s_defaultSpot = Resources.Load<Texture2D>("DefaultSpotCookie");
            }
            return s_defaultSpot;
        }
    }

    public void UpdateBinding() {
        var lightCache = Light;
        var lightRange = lightCache.range;
        var lightSize = lightRange * 2.0f;

#if UNITY_EDITOR
        EnsureCookie();
#endif

        m_length = Mathf.Clamp(m_length, 0.0f, lightSize);
        m_intensity = Mathf.Max(m_intensity, 0.0f);

        // Multiply intensity into color to get uncapped values. Unity's
        // light.intensity is implicitly capped to 8, so it is unusable.
        var col = lightCache.color;
        col.r = m_color.r;
        col.g = m_color.g;
        col.b = m_color.b;
        col *= m_intensity; // Color is in gamma space, so mul directly.
        
        if (lightCache.type == LightType.Directional) {
            m_radius = Mathf.Clamp(m_radius, 0.0f, 1.0f);

            // Compensate for 0.1 in shader.
            col.a = m_radius * 10.0f;
        }
        else {
            m_radius = Mathf.Clamp(m_radius, 0.0f, lightRange);

            // Store radius & length as a normalized weights, and recover in shader.
            float radiusWeight = m_radius / lightRange;
            float lengthWeight = m_length / lightSize;

            // Clamp radius to less than one to remove extra multiply in shader.
            col.a = Mathf.Min(radiusWeight, 0.999f) + Mathf.Ceil(lengthWeight * 1000.0f);
        }

        // Use sign for specular highlight toggle.
        col.a = Mathf.Max(c_minimumLightSize, col.a); // Must be non-zero!
        col.a *= (m_hasSpecularHightlight ? 1.0f : -1.0f);
        lightCache.color = col;

        // Unity implicitly multiplies color by intensity when uploading
        // it to the shader. So we need it to be one to avoid messing up
        // size stored in alpha.
        lightCache.intensity = 1.0f;

        m_lastRange = lightRange;
    }

#if UNITY_EDITOR
    public void EnsureCookie() {
        var setLight = Light;

        if (setLight.type == LightType.Spot && setLight.cookie == null) {
            setLight.cookie = DefaultSpotLightCookie;
            EditorUtility.SetDirty(this);
        }else if (setLight.type == LightType.Point && setLight.cookie == DefaultSpotLightCookie) {
            setLight.cookie = null;
            EditorUtility.SetDirty(this);
        }
    }
#endif

    private void Reset() {
        var l = GetComponent<Light>();
        
        if (l != null) {
            m_color.r = l.color.r;
            m_color.g = l.color.g;
            m_color.b = l.color.b;
            m_intensity = l.intensity;
        } else {
            m_color.r = 1.0f;
            m_color.g = 1.0f;
            m_color.b = 1.0f;
            m_intensity = 1.0f;
        }
        
        m_hasSpecularHightlight = true;
        m_color.a = c_minimumLightSize;
        m_radius = 0.0f;

        UpdateBinding ();
    }
    
    private void Update() {
        if (Light.range != m_lastRange) {
            UpdateBinding();
        }
    }
}
