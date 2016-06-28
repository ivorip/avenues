using UnityEngine;
using System.Collections;

public class orientLookAt : MonoBehaviour {
    
    
	// Update is called once per frame
	void Update () {

        var targetPos = Camera.main.transform.position;
        targetPos.y = transform.position.y;
        
        float size = (targetPos - transform.position).magnitude;
        transform.localScale = new Vector3(size, size, size) * 0.02f;
        
        var newRotation = Quaternion.LookRotation(targetPos - transform.position);
        transform.rotation = newRotation;
      
	
	}
}
