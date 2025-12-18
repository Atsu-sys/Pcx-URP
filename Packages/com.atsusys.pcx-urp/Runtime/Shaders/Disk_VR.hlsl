// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx
// URP version by Atsu-sys

#ifndef PCX_DISK_INCLUDED
#define PCX_DISK_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Common.hlsl"

// Uniforms
CBUFFER_START(UnityPerMaterial)
    half4 _Tint;
    half _PointSize;
CBUFFER_END

float4x4 _Transform;

#if _COMPUTE_BUFFER
StructuredBuffer<float4> _PointBuffer;
#endif

// Color channel swap function
half3 SwapColorChannels(half3 col)
{
    #if defined(_COLORORDER_BGR)
        return col.bgr;
    #elif defined(_COLORORDER_GBR)
        return col.gbr;
    #elif defined(_COLORORDER_GRB)
        return col.grb;
    #elif defined(_COLORORDER_BRG)
        return col.brg;
    #elif defined(_COLORORDER_RBG)
        return col.rbg;
    #else // _COLORORDER_RGB (default)
        return col.rgb;
    #endif
}

// Vertex input attributes
struct Attributes
{
#if _COMPUTE_BUFFER
    uint vertexID : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID // Added for VR (though mostly manual in compute buffer path)
#else
    float4 position : POSITION;
    half3 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID // Added for VR
#endif
};

// Fragment varyings
struct Varyings
{
    float4 position : SV_POSITION;
#if !PCX_SHADOW_CASTER
    half3 color : COLOR;
    float fogFactor : TEXCOORD0;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID // Added for VR
    UNITY_VERTEX_OUTPUT_STEREO     // Added for VR
};

// Vertex phase
#if _COMPUTE_BUFFER
Varyings Vertex(uint vid : SV_VertexID, uint instanceID : SV_InstanceID)
#else
Varyings Vertex(Attributes input)
#endif
{
    Varyings o = (Varyings)0;

#if _COMPUTE_BUFFER
    // VR: Manual setup using instanceID passed from SV_InstanceID
    UnitySetupInstanceID(instanceID);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 pt = _PointBuffer[vid];
    float4 pos = mul(_Transform, float4(pt.xyz, 1));
    half3 col = PcxDecodeColor(asuint(pt.w));
#else
    // VR: Standard setup
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 pos = input.position;
    half3 col = input.color;
#endif

#if !PCX_SHADOW_CASTER
    // Apply color channel swap
    col = SwapColorChannels(col);

    // Color space convertion & applying tint
    #if defined(UNITY_COLORSPACE_GAMMA)
        col *= _Tint.rgb * 2;
    #else
        // Linear to Gamma conversion for tint, then back to Linear
        half3 tintGamma = pow(max(_Tint.rgb, 0.0001), 1.0 / 2.2);
        col *= tintGamma * 2;
        col = pow(max(col, 0.0001), 2.2);
    #endif
#endif

    // Set vertex output.
    // o.position = TransformObjectToHClip(pos.xyz); // Removed: Done in Geometry shader or redundant?
    // Wait, Disk shader usually does View Space calculations in Geometry shader?
    // Let's check original Disk.hlsl.
    // Original Disk.hlsl (Step 356) does: o.position = TransformObjectToHClip(pos.xyz);
    // AND then Geometry shader takes it as "origin".
    // Wait, if Geometry shader expands it, it expects "origin" to be in Clip Space?
    // Step 356 Lines 83-91:
    // float4 origin = input[0].position;
    // float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);
    // float radius = extent.y / origin.w * _ScreenParams.y;
    // This logic implies input position is in CLIP SPACE (homogeneous).
    // UNITY_MATRIX_P._11_22 suggests accessing Projection Matrix directly.
    
    o.position = TransformObjectToHClip(pos.xyz);

#if !PCX_SHADOW_CASTER
    o.color = col;
    o.fogFactor = ComputeFogFactor(o.position.z);
#endif
    return o;
}

// Geometry phase
[maxvertexcount(36)]
void Geometry(point Varyings input[1], inout TriangleStream<Varyings> outStream)
{
    // VR: Setup Instance ID from input
    UNITY_SETUP_INSTANCE_ID(input[0]);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0]);

    float4 origin = input[0].position;
    float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);

    // Copy the basic information.
    Varyings o = input[0];
    
    // VR: Transfer stereo info from input to output
    UNITY_TRANSFER_INSTANCE_ID(input[0], o);
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], o);

    // Determine the number of slices based on the radius of the
    // point on the screen.
    float radius = extent.y / origin.w * _ScreenParams.y;
    uint slices = min((radius + 1) / 5, 4) + 2;

    // Slightly enlarge quad points to compensate area reduction.
    // Hopefully this line would be complied without branch.
    if (slices == 2) extent *= 1.2;

    // Top vertex
    o.position.y = origin.y + extent.y;
    o.position.xzw = origin.xzw;
    outStream.Append(o);

    UNITY_LOOP for (uint i = 1; i < slices; i++)
    {
        float sn, cs;
        sincos(PI / slices * i, sn, cs);

        // Right side vertex
        o.position.xy = origin.xy + extent * float2(sn, cs);
        outStream.Append(o);

        // Left side vertex
        o.position.x = origin.x - extent.x * sn;
        outStream.Append(o);
    }

    // Bottom vertex
    o.position.x = origin.x;
    o.position.y = origin.y - extent.y;
    outStream.Append(o);

    outStream.RestartStrip();
}

half4 Fragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if PCX_SHADOW_CASTER
    return 0;
#else
    half4 c = half4(input.color, _Tint.a);
    c.rgb = MixFog(c.rgb, input.fogFactor);
    return c;
#endif
}

#endif // PCX_DISK_INCLUDED
