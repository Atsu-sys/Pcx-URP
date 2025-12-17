// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx
// URP version by Atsu-sys

Shader "Point Cloud/Disk URP VR"
{
    Properties
    {
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _PointSize("Point Size", Float) = 0.05
        [KeywordEnum(RGB, BGR, GBR, GRB, BRG, RBG)] _ColorOrder("Color Order", Float) = 0
        _Rotation("Rotation", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Cull Off
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment

            #pragma multi_compile_fog
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma shader_feature_local _COLORORDER_RGB _COLORORDER_BGR _COLORORDER_GBR _COLORORDER_GRB _COLORORDER_BRG _COLORORDER_RBG
            #pragma multi_compile_instancing 

            #include "Disk_VR.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma multi_compile_instancing

            #define PCX_SHADOW_CASTER 1
            #include "Disk_VR.hlsl"
            ENDHLSL
        }
        
        // DepthOnly pass for depth prepass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            
            ColorMask 0
            ZWrite On

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma multi_compile_instancing

            #define PCX_SHADOW_CASTER 1
            #include "Disk_VR.hlsl"
            ENDHLSL
        }
    }

    // Fallback for non-URP
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _COLORORDER_RGB _COLORORDER_BGR _COLORORDER_GBR _COLORORDER_GRB _COLORORDER_BRG _COLORORDER_RBG

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_Position;
                half3 color : COLOR;
                half psize : PSIZE;
                UNITY_FOG_COORDS(0)
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            half4 _Tint;
            half _PointSize;
            half4 _Rotation;

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
                #else
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

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                float4 pos = v.vertex;
                if (any(_Rotation.xyz)) pos.xyz = RotatePoint(pos.xyz, _Rotation.xyz);

                o.pos = UnityObjectToClipPos(pos);
                half3 col = SwapColorChannels(v.color);
                o.color = col * _Tint.rgb * 2;
                o.psize = _PointSize / o.pos.w * _ScreenParams.y;
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half4 c = half4(i.color, _Tint.a);
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
    
    CustomEditor "Pcx.DiskMaterialInspector"
}
