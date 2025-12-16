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
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

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
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma multi_compile_instancing
            #define PCX_SHADOW_CASTER 1
            #include "Disk_VR.hlsl"
            ENDHLSL
        }

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
            #include "Disk_VR.hlsl"
            ENDHLSL
        }
    }
    
    // Fallback for Built-in RP (Based on User's Sample Code)
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
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
                float4 vertex : SV_POSITION;
                half3 color : COLOR;
                UNITY_FOG_COORDS(0)
                UNITY_VERTEX_INPUT_INSTANCE_ID 
                UNITY_VERTEX_OUTPUT_STEREO 
            };

            half4 _Tint;
            half _PointSize;

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

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // Pass object space position to geometry shader
                o.vertex = v.vertex;
                
                half3 col = SwapColorChannels(v.color);
                o.color = col * _Tint.rgb * 2;
                
                UNITY_TRANSFER_FOG(o, UnityObjectToClipPos(v.vertex));
                return o;
            }

            [maxvertexcount(4)]
            void geom(point v2f input[1], inout TriangleStream<v2f> outStream)
            {
                UNITY_SETUP_INSTANCE_ID(input[0]);

                float3 center = input[0].vertex.xyz;
                // Calculate View Space extent via Projection Matrix (Pcx style) or simple billboard?
                // Pcx style: half2 named extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);
                // But in Geometry shader here, we are in Object Space? No, Pcx Geometry shader expects Clip Space?
                // Wait, Pcx Disk.hlsl vertex shader output is Clip Space (HClip).
                // But here in Fallback, I output Object Space `v.vertex`.
                // So I should do billboard logic in Object or View Space.
                
                // Let's use View Space Billboard logic similar to User Sample
                float3 viewPos = UnityObjectToViewPos(input[0].vertex);
                float halfS = _PointSize * 0.5;
                
                // Billboard vectors in View Space
                float3 right = float3(1, 0, 0);
                float3 up    = float3(0, 1, 0);

                float3 corners[4];
                corners[0] = -right * halfS - up * halfS; // BL
                corners[1] =  right * halfS - up * halfS; // BR
                corners[2] = -right * halfS + up * halfS; // TL
                corners[3] =  right * halfS + up * halfS; // TR

                for(int i=0; i<4; i++)
                {
                    v2f o;
                    UNITY_INITIALIZE_OUTPUT(v2f, o);
                    UNITY_TRANSFER_INSTANCE_ID(input[0], o);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                    float3 pos = viewPos + corners[i];
                    o.vertex = mul(UNITY_MATRIX_P, float4(pos, 1)); // View to Clip
                    
                    o.color = input[0].color;
                    UNITY_TRANSFER_FOG(o, o.vertex);
                    outStream.Append(o);
                }
                outStream.RestartStrip();
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 c = half4(i.color, _Tint.a);
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
    
    CustomEditor "Pcx.DiskMaterialInspector"
}
