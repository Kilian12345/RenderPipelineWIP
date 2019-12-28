using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/My Post-Processing Stack")]
public class MyPostProcessingStack : ScriptableObject
{

	static Mesh fullScreenTriangle;
	static Material material;
	static int mainTexId = Shader.PropertyToID("_MainTex");

	static void InitializeStatic()
	{
		if (fullScreenTriangle)
		{
			return;
		}
		fullScreenTriangle = new Mesh
		{
			name = "My Post-Processing Stack Full-Screen Triangle",
			vertices = new Vector3[] {
				new Vector3(-1f, -1f, 0f),
				new Vector3(-1f,  3f, 0f),
				new Vector3( 3f, -1f, 0f)
			},
			triangles = new int[] { 0, 1, 2 },
		};
		fullScreenTriangle.UploadMeshData(true);

		material =
			new Material(Shader.Find("My Pipeline/TutoPostPro"))
			{
				name = "My Post-Processing Stack material",
				hideFlags = HideFlags.HideAndDontSave
			};
	}

	public void Render(CommandBuffer cb, int cameraColorId , int cameraDepthId)
	{
		cb.SetGlobalTexture(mainTexId, cameraColorId);
		InitializeStatic();
		Debug.Log(material + "material");
		cb.SetRenderTarget(
			BuiltinRenderTextureType.CameraTarget,
			RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store
		);
		cb.DrawMesh(fullScreenTriangle, Matrix4x4.identity, material);
	}
}
