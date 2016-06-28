using UnityEngine;
using System.Collections;

public class Movement : MonoBehaviour
{
    public float moveSpeed = 5f;
    public float riseSpeed = 15f;
    private float speedMultiply = 1f;
    private Camera m_Camera;
    //public float turnSpeed = 50f;
    

    void Start() {
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;
        m_Camera = Camera.main;
        
    }

    void Update()
    {
        Transform p = m_Camera.transform;

        if (Input.GetKeyDown("escape"))
            {
                Cursor.visible = true;
                Cursor.lockState = CursorLockMode.None;
            }
        


        if (Input.GetKey(KeyCode.LeftShift))
            {
                speedMultiply = 3.0f;
            }
        else if (Input.GetKey(KeyCode.LeftAlt))
            {
                speedMultiply = 0.3f;
            }
        else 
            {
                speedMultiply = 1.0f;
            }



        //Move Foward/Back
        if (Input.GetAxis("Vertical") != 0)
        {
            transform.Translate(Mathf.Sign(Input.GetAxis("Vertical")) * p.forward * moveSpeed * Time.deltaTime * 2f * speedMultiply);
        }         

        if (Input.GetKey(KeyCode.W))
            transform.Translate(p.forward * moveSpeed * Time.deltaTime * speedMultiply);

        if (Input.GetMouseButton(0))
            transform.Translate(p.forward * moveSpeed * Time.deltaTime * speedMultiply);

        //Move Back
        if (Input.GetKey(KeyCode.S))
             transform.Translate(-p.forward * moveSpeed * Time.deltaTime  * speedMultiply);

        if (Input.GetMouseButton(1))
            transform.Translate(-p.forward * moveSpeed * Time.deltaTime * speedMultiply);


        //Ascend/Descend        

        if (Input.GetAxis("Mouse ScrollWheel") != 0f)
        {
            float mouseY = Input.GetAxis("Mouse ScrollWheel");
            if (Mathf.Abs(mouseY) > 0.05f)
            {
                transform.Translate(mouseY * Vector3.up * moveSpeed * Time.deltaTime * 1f * speedMultiply);
            }
        }

        if (Input.GetKey(KeyCode.R))
            transform.Translate(Vector3.up * riseSpeed * Time.deltaTime * 10f * speedMultiply);
        

        if (Input.GetKey(KeyCode.F))
            transform.Translate(Vector3.down * riseSpeed * Time.deltaTime *10f * speedMultiply);

        

        if (Input.GetAxis("TriggerLeft") != 0f)
        {
            float triggerLeft = Input.GetAxis("TriggerLeft");
            transform.Translate(triggerLeft * Vector3.down * moveSpeed * Time.deltaTime * 1f * speedMultiply);
        }


        if (Input.GetAxis("TriggerRight") != 0f)
        {
            float triggerRight = Input.GetAxis("TriggerRight");
            transform.Translate(triggerRight * Vector3.up * moveSpeed * Time.deltaTime * 1f * speedMultiply);
        }



        //Horizontal Movements
        if (Input.GetKey(KeyCode.A))
            transform.Translate(-p.right * moveSpeed * Time.deltaTime * speedMultiply);

        if (Input.GetKey(KeyCode.D))
            transform.Translate(p.right * moveSpeed * Time.deltaTime * speedMultiply);

        if (Input.GetAxis("Horizontal") != 0f)
        {
            float joyH = Input.GetAxis("Horizontal");
            //Debug.Log(Input.GetAxis("Horizontal"));

            if (Mathf.Abs(joyH) > 0.10f)
            {
                transform.Translate(joyH * p.right * moveSpeed * Time.deltaTime * 1f * speedMultiply);
            }
            
        }


    }
}