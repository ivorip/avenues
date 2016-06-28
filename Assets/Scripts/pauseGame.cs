using UnityEngine;
using System.Collections;

public class pauseGame : MonoBehaviour {
    private bool CanPause = true;
    private Camera m_Camera;
    public GameObject txtPaused;
    void Start()
    {
        m_Camera = Camera.main;
    }


    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
        {
            if (CanPause)
            {
                Debug.Log("pause");
                Time.timeScale = 0;
                m_Camera.GetComponent<mouselook>().enabled = false;
                Cursor.visible = true;
                Cursor.lockState = CursorLockMode.None;
                txtPaused.SetActive(true);
                CanPause = false;
            }
            else
            {
                Time.timeScale = 1;
                m_Camera.GetComponent<mouselook>().enabled = true;
                Cursor.visible = false;
                Cursor.lockState = CursorLockMode.Locked;
                txtPaused.SetActive(false);
                CanPause = true;
            }
        }
    }
}
