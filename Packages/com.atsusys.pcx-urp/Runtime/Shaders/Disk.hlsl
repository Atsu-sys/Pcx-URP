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
    half4 _Rotation;
    half _Density;
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

float3 RotatePoint(float3 p, float3 angles)
{
    float3 rad = angles * (3.14159265359 / 180.0);
    float3 s, c;
    sincos(rad, s, c);
    float3 p1 = p;
    p1.yz = float2(p.y * c.x - p.z * s.x, p.y * s.x + p.z * c.x);
    float3 p2 = p1;
    p2.xz = float2(p1.x * c.y + p1.z * s.y, -p1.x * s.y + p1.z * c.y);
    float3 p3 = p2;
    p3.xy = float2(p2.x * c.z - p2.y * s.z, p2.x * s.z + p2.y * c.z);
    return p3;
}

// Vertex input attributes
struct Attributes
{
#if _COMPUTE_BUFFER
    uint vertexID : SV_VertexID;
#else
    float4 position : POSITION;
    half3 color : COLOR;
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
};

// Vertex phase
Varyings Vertex(Attributes input)
{
    // Retrieve vertex attributes.
#if _COMPUTE_BUFFER
    float4 pt = _PointBuffer[input.vertexID];
    float4 pos = mul(_Transform, float4(pt.xyz, 1));
    half3 col = PcxDecodeColor(asuint(pt.w));
#else
    float4 pos = input.position;
    half3 col = input.color;
#endif

#if !PCX_SHADOW_CASTER
    // Apply rotation
    if (any(_Rotation.xyz))
    {
        pos.xyz = RotatePoint(pos.xyz, _Rotation.xyz);
    }

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
    Varyings o;
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
    float4 origin = input[0].position;
    float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);

    // Copy the basic information.
    Varyings o = input[0];

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
#if PCX_SHADOW_CASTER
    return 0;
#else
    // Density-based discard
    if (_Density < 1.0)
    {
        float hash = frac(sin(dot(input.position.xy, float2(12.9898, 78.233))) * 43758.5453);
        if (hash > _Density) discard;
    }
    
    half4 c = half4(input.color, _Tint.a);
    c.rgb = MixFog(c.rgb, input.fogFactor);
    return c;
#endif
}

#endif // PCX_DISK_INCLUDED
