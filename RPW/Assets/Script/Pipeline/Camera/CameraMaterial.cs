using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMaterial : MonoBehaviour
{
    //material that's applied when doing postprocessing
    public Material postprocessMaterial;

    private Camera cam;

    private void Start()
    {
        //get the camera and tell it to render a depthnormals texture
        cam = GetComponent<Camera>();
        cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.DepthNormals;
    }

    //method which is automatically called by unity after the camera is done rendering
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //draws the pixels from the source texture to the destination texture
        Debug.Log("ca tourne");
        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
