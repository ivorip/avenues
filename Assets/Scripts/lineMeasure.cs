using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class lineMeasure : MonoBehaviour
{
    public GameObject hitpointPrefab;
    public float lineWidth = 0.05f;
    public GameObject lblMeasurement;

    private int numClicks;
    private Camera m_Camera;
    private RaycastHit theHit;
    private GameObject point1;
    private GameObject point1end;
    private GameObject point2;
    private GameObject point1Line;
    private GameObject point2Line;
    private Material lineMaterial;


    // Use this for initialization
    void Start()
    {
        setInitial();
    }


    void setInitial()
    {
        lblMeasurement.SetActive(false);
        lineMaterial = (Material)Resources.Load("green", typeof(Material));
        numClicks = 0;
    }
 
    // Update is called once per frame
    void Update()
    {
        Debug.DrawRay(transform.position, transform.forward, Color.red);

        if (Input.GetKeyDown(KeyCode.M))
        {
            switch (numClicks)
            {
                case 0:
                    //Clear measurements

                    lblMeasurement.SetActive(false);

                    DestroyImmediate(point1);
                    DestroyImmediate(point1end);
                    DestroyImmediate(point2);
                    DestroyImmediate(point1Line);
                    DestroyImmediate(point2Line);
                    numClicks = 1;
                    break;
                case 1:

                    //Check if it hits something
                    if (Physics.Raycast(transform.position, transform.forward, out theHit))
                    {
                        point1 = Instantiate(hitpointPrefab, theHit.point, Quaternion.identity) as GameObject;
                        point1.name = "point1";

                        lblMeasurement.SetActive(true);
                        string addText = ("Point 1: " + theHit.point);
                        lblMeasurement.gameObject.GetComponent<Text>().text=addText;


                        //Check if there's vertical clearance
                        RaycastHit p1Height;
                        if (Physics.Raycast(theHit.point, new Vector3(0, 1, 0), out p1Height))
                        {

                            point1end = Instantiate(hitpointPrefab, p1Height.point, Quaternion.identity) as GameObject;

                            point1Line = new GameObject();
                            point1Line.name = "Line1";
                            point1Line.transform.position = point1.transform.position;
                            point1Line.AddComponent<LineRenderer>();
                            LineRenderer lr = point1Line.GetComponent<LineRenderer>();

                            lr.material = lineMaterial;
                            lr.SetWidth(lineWidth, lineWidth);
                            lr.SetPosition(0, point1.transform.position);
                            lr.SetPosition(1, point1end.transform.position);

                            addText = ("\nPoint 1 vertical clearance: " + mToFt(Vector3.Distance(point1.transform.position, point1end.transform.position)));
                            lblMeasurement.GetComponent<Text>().text += addText;

                        }

                        //Don't advance unless a hit is detected
                        numClicks = 2;
                    }

                    break;
                case 2:
                    //Check if it hits second point
                    if (Physics.Raycast(transform.position, transform.forward, out theHit))
                    {

                        point2 = Instantiate(hitpointPrefab, theHit.point, Quaternion.identity) as GameObject;
                        point2.name = "point2";

                        Vector3 point3 = new Vector3(point2.transform.position.x, point1.transform.position.y, point2.transform.position.z);

                        string angleA = string.Format("{0:0.00}", Vector3.Angle(point2.transform.position - point1.transform.position, point3 - point1.transform.position)) + " degrees";
                        
                        
                        

                        string addText = ("\nPoint2: " + point2.transform.position);
                        addText += ("\nPoint1 to Point2: " + mToFt(Vector3.Distance(point1.transform.position, point2.transform.position)));
                        addText += ("\nAngle from horizontal: " + angleA);
                        lblMeasurement.GetComponent<Text>().text += addText;


                        //Draw second line
                        point2Line = new GameObject();
                        point2Line.name = "Line2";
                        point2Line.transform.position = point2.transform.position;
                        point2Line.AddComponent<LineRenderer>();

                        LineRenderer lr = point2Line.GetComponent<LineRenderer>();
                        lr.material = lineMaterial;
                        lr.SetWidth(lineWidth, lineWidth);
                        lr.SetPosition(0, point1.transform.position);
                        lr.SetPosition(1, point2.transform.position);

                    }
                    //Advance whether it hits or not, next click clears objects
                    numClicks = 0;
                    break;
                default:
                    break;
            }
        }
    }

    private string mToFt(float u)
    {
        int feet = (int)(u * 3.2808399f);
        string inches = string.Format("{0:0.00}", (((u * 3.2808399f)-feet)*12f));
        string output = (feet + "\' " + inches + "\"");
        return output;
    }
}
