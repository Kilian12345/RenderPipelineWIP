using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/My Post-Processing Stack")]
public class MyPostProcessingStack : ScriptableObject
{

	public void Render(CommandBuffer cb, int cameraColorId , int cameraDepthId)
	{
		cb.Blit(cameraColorId, BuiltinRenderTextureType.CameraTarget);
	}
}
