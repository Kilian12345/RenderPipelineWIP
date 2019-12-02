using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using Conditional = System.Diagnostics.ConditionalAttribute;

public class MyPipeline : RenderPipeline
{
    CullResults cull;
    CommandBuffer cameraBuffer = new CommandBuffer { name = "Render Camera" };

    Material errorMaterial;

    //light buffer
    const int maxVisibleLights = 4;
    static int visibleLightColoredId = Shader.PropertyToID("_VisibleLightColors");
    static int visibleLightDirectionsId = Shader.PropertyToID("_VisibleLightDirections");

    Vector4[] visibleLightColors = new Vector4[maxVisibleLights];
    Vector4[] visibleLightDirections = new Vector4[maxVisibleLights];

    void Render(ScriptableRenderContext context, Camera camera)
    {
        ScriptableCullingParameters cullingParameters;
        if(!CullResults.GetCullingParameters(camera, out cullingParameters))
        { return; }


#if UNITY_EDITOR
        if (camera.cameraType == CameraType.SceneView)
        { ScriptableRenderContext.EmitWorldGeometryForSceneView(camera); }
#endif

        CullResults.Cull(ref cullingParameters, context, ref cull);


        context.SetupCameraProperties(camera);
        CameraClearFlags clearFlags = camera.clearFlags;
        cameraBuffer.ClearRenderTarget(
            (clearFlags & CameraClearFlags.Depth) != 0,
            (clearFlags & CameraClearFlags.Color) != 0,
            camera.backgroundColor
        );

        ConfigureLights();

        cameraBuffer.BeginSample("Render Camera");
        // Light buffer
        cameraBuffer.SetGlobalVectorArray(visibleLightColoredId, visibleLightColors);
        cameraBuffer.SetGlobalVectorArray(visibleLightDirectionsId, visibleLightDirections);

        context.ExecuteCommandBuffer(cameraBuffer);
        cameraBuffer.Clear();

        //draw 
        var drawSettings = new DrawRendererSettings( camera, new ShaderPassName("SRPDefaultUnlit"));
        drawSettings.flags = drawFlags;
        drawSettings.sorting.flags = SortFlags.CommonOpaque;

        var filterSettings = new FilterRenderersSettings(true) { renderQueueRange = RenderQueueRange.opaque };
        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);
        context.DrawSkybox(camera);

        drawSettings.sorting.flags = SortFlags.CommonTransparent;
        filterSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        DrawDefaultPipeline(context, camera);

        cameraBuffer.EndSample("Render Camera");
        context.ExecuteCommandBuffer(cameraBuffer);
        cameraBuffer.Clear();

        context.Submit();
    }

    public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
    {
        base.Render(renderContext, cameras);

        foreach (var camera in cameras)
        {
            Render(renderContext, camera);
        }
    }

    [Conditional("UNITY_EDITOR")]
    void DrawDefaultPipeline(ScriptableRenderContext context, Camera camera)
    {
        if(errorMaterial == null)
        {
            Shader errorShader = Shader.Find("Hidden/InternalErrorShader");
            errorMaterial = new Material(errorShader) { hideFlags = HideFlags.HideAndDontSave};
        }

        var drawSettings = new DrawRendererSettings(camera, new ShaderPassName("ForwardBase"));

        drawSettings.SetShaderPassName(1, new ShaderPassName("PrepassBase"));
        drawSettings.SetShaderPassName(2, new ShaderPassName("Always"));
        drawSettings.SetShaderPassName(3, new ShaderPassName("Vertex"));
        drawSettings.SetShaderPassName(4, new ShaderPassName("VertexLMRGBM"));
        drawSettings.SetShaderPassName(5, new ShaderPassName("VertexLM"));
        drawSettings.SetOverrideMaterial(errorMaterial, 0);

        var filterSettings = new FilterRenderersSettings(true);

        context.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);
    }

    DrawRendererFlags drawFlags;

    public MyPipeline(bool dynamicBatching, bool instancing)
    {
        GraphicsSettings.lightsUseLinearIntensity = true; // Change the light from Gamma space to Linear space

        if(dynamicBatching)
        {
            drawFlags = DrawRendererFlags.EnableDynamicBatching;
        }
        if (instancing)
        {
            drawFlags |= DrawRendererFlags.EnableInstancing;
        }
    }

    void ConfigureLights()
    {
        for(int i = 0; i < cull.visibleLights.Count; i++)
        {
            VisibleLight light = cull.visibleLights[i];
            visibleLightColors[i] = light.finalColor;
            Vector4 v = light.localToWorld.GetColumn(2);
            v.x = -v.x;
            v.y = -v.y;
            v.z = -v.z;
            visibleLightDirections[i] = v;
        }
    }
}
