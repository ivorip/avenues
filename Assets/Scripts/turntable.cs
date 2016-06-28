using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class turntable : MonoBehaviour {
    public GameObject axis;
    public GameObject lblTurntable;
    public GameObject camPos;
   
    private Vector3 spinVector;
    private Transform myTransform;
    public static bool orbitState=false;
    private float orbitSpeed=20f;
    private Camera m_Camera;
    string gameStatus;

	// Use this for initialization
	void Start () {
        spinVector = axis.transform.up;
        m_Camera = Camera.main;
        myTransform = transform;     
	}

    // Update is called once per frame
    void Update() {

        if (Input.GetKeyDown(KeyCode.Alpha0))
        {
            orbitState = !orbitState;
            myTransform.transform.position = camPos.transform.position;
            m_Camera.transform.LookAt(axis.transform.position);
            updateStatus();
        }

        if (orbitState)
        {
            if (Input.GetKeyDown(KeyCode.Equals))
            {
                orbitSpeed++;
                updateStatus();
            }
            else if (Input.GetKeyDown(KeyCode.Minus))
            {
                orbitSpeed--;
                updateStatus();
            }
            myTransform.RotateAround(axis.transform.position, spinVector, Time.deltaTime * orbitSpeed);
        }


    }

    void updateStatus()
    {
        gameStatus = ("Turntable mode On -  " + "Speed: " + orbitSpeed);
        lblTurntable.GetComponent<Text>().text = gameStatus;
        lblTurntable.SetActive(orbitState);
    }
}
