#ifndef MYRP_OUTLINE_INCLUDED
#define MYRP_OUTLINE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"


CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixVP;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
CBUFFER_END

CBUFFER_START(UnityPerCamera)
float4 _ProjectionParams;
CBUFFER_END

#define UNITY_MATRIX_M unity_ObjectToWorld

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


sampler2D _MainTex;
            //the depth normals texture
sampler2D _CameraDepthNormalsTexture;
            //texelsize of the depthnormals texture
float4 _CameraDepthNormalsTexture_TexelSize;

float4 _OutlineColor;
float _NormalMult;
float _NormalBias;
float _DepthMult;
float _DepthBias;

struct VertexInput
{
    float4 pos : POSITION;
    float3 uv : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};



//
// cginc Values__ __
//

inline float DecodeFloatRG(float2 enc)
{
    float2 kDecodeDot = float2(1.0, 1 / 255.0);
    return dot(enc, kDecodeDot);
}

inline float3 DecodeViewNormalStereo(float4 enc4)
{
    float kScale = 1.7777;
    float3 nn = enc4.xyz * float3(2 * kScale, 2 * kScale, 0) + float3(-kScale, -kScale, 1);
    float g = 2.0 / dot(nn.xyz, nn.xyz);
    float3 n;
    n.xy = g * nn.xy;
    n.z = g - 1;
    return n;
}

inline void DecodeDepthNormal(float4 enc, out float depth, out float3 normal)
{
    depth = DecodeFloatRG(enc.zw);
    normal = DecodeViewNormalStereo(enc);
}

//
// cginc Values__ __
//

void Compare(inout float depthOutline, inout float normalOutline,
                    float baseDepth, float3 baseNormal, float2 uv, float2 offset)
{
                //read neighbor pixel
    float4 neighborDepthnormal = tex2D(_CameraDepthNormalsTexture,
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
    
    float3 neighborNormal;
    float neighborDepth;
    DecodeDepthNormal(neighborDepthnormal, neighborDepth, neighborNormal);
    neighborDepth = neighborDepth * _ProjectionParams.z;

    float depthDifference = baseDepth - neighborDepth;
    depthOutline = depthOutline + depthDifference;

    float3 normalDifference = baseNormal - neighborNormal;
    normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
    normalOutline = normalOutline + normalDifference;
}

VertexOutput OutlinePassVert(VertexInput input)
{
    VertexOutput output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0));
    output.pos = mul(unity_MatrixVP, worldPos);
    output.pos = mul(output.pos, input.pos);
    output.uv = input.uv;

    return output;
}

float4 OutlinePassFrag(VertexOutput input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    float4 depthnormal = tex2D(_CameraDepthNormalsTexture, input.uv);

                //decode depthnormal
    float3 normal;
    float depth;
    DecodeDepthNormal(depthnormal, depth, normal);

                //get depth as distance from camera in units 
    depth = depth * _ProjectionParams.z;

    float depthDifference = 0;
    float normalDifference = 0;

    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(1, 0));
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(0, 1));
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(0, -1));
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(-1, 0));

    depthDifference = depthDifference * _DepthMult;
    depthDifference = saturate(depthDifference);
    depthDifference = pow(depthDifference, _DepthBias);

    normalDifference = normalDifference * _NormalMult;
    normalDifference = saturate(normalDifference);
    normalDifference = pow(normalDifference, _NormalBias);

    float outline = normalDifference + depthDifference;
    float4 sourceColor = tex2D(_MainTex, input.uv);
    float4 color = lerp(sourceColor, _OutlineColor, outline);
    
    //return color;
    return float4(1, 0, 0, 1);
}

#endif // MYRP_OUTLINE_INCLUDED