using UnityEngine;
using System.Collections;

public class Waypoint : MonoBehaviour {

    public GameObject[] waypoints;
    
    public float moveSpeed = 50f;
    public float turnSpeed = 50f;
    public GameObject txtStatus;
    private int camindex =0;

    private float moveEnd = 3f;
    private float moveStart;
    private float movePercentage=0f;

    private bool isLerping = false;
    private Vector3 _startPosition;
    private Vector3 _endPosition;
    private Quaternion _startRotation;
    private Quaternion _endRotation;
    private Camera m_Camera;
    
    // Use this for initialization
    void Start () {
        m_Camera = Camera.main;
    }
	
	// Update is called once per frame
	void FixedUpdate () {

        //Check if its moving
        if (isLerping)
        {
            moveIt();
        }

        //Check if key is pressed
        if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            turntable.orbitState = false;
            txtStatus.SetActive(false);
            if (!isLerping)
            {
                //Turn off mouselook
                //m_Camera.GetComponent<MouseLookCameraRig>().enabled = false;
                //Increment target index

                camindex = camindex + 1;
                if (camindex > waypoints.Length - 1)
                {
                    camindex = 0;
                }


                isLerping = true;

                moveStart = Time.time;
                _startPosition = transform.position;
                _startRotation = m_Camera.transform.rotation;
                _endPosition = waypoints[camindex].transform.position;
                _endRotation = waypoints[camindex].transform.rotation;
            }

        }

    }


    void moveIt()
    {
        movePercentage = Mathf.Clamp01((Time.time - moveStart) / moveEnd);
        transform.position = Vector3.Lerp(_startPosition, _endPosition, movePercentage);
        m_Camera.transform.rotation = Quaternion.Slerp(_startRotation, _endRotation, movePercentage);

        if (movePercentage >= 1)
        {

            isLerping = false;
            //Turn Mouse Look On
            //m_Camera.GetComponent<MouseLookCameraRig>().enabled = true;

        }
    }
}
