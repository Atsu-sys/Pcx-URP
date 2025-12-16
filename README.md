PCX for URP - Point Cloud Importer/Renderer for Unity
======================================================

![GIF](https://i.imgur.com/zc6P96x.gif)
![GIF](https://i.imgur.com/lpWIiXu.gif)

PCX for URP は、Unityの Universal Render Pipeline (URP) 環境において、ポイントクラウド（点群）データをインポート・レンダリングするためのカスタムパッケージです。

クレジット / 前提 本プロジェクトは、Keijiro Takahashi 氏によるライブラリ keijiro/Pcx をフォークし、URP および Unity 6 環境で動作するように改修・最適化を行ったものです。

## システム要件 (System Requirements)
Unity: Unity 6 (6000.0 以上)

Pipeline: Universal Render Pipeline (URP) 17.0.0 以上

## インストール方法 (Installation)

Unity エディタで Window > Package Manager を開く。

左上の + ボタンをクリックし、Add package from git URL... を選択。

以下のURLを入力して Add をクリックしてください。

```
https://github.com/Atsu-sys/Pcx-URP.git?path=Packages/com.atsusys.pcx-urp
```

## クイックスタート
用途に合わせて2つの使用方法があります。

### 方法1: Mesh + MeshRenderer (シンプル・VR対応)
標準的なMeshとして扱いたい場合の手順です。**VRプロジェクトではこちらを推奨します。**

インポート設定: .ply ファイルを選択し、Inspectorで Container Type を Mesh に設定して Apply します。

シーン配置: GameObjectを作成し、Mesh Filter と Mesh Renderer を追加します。

マテリアル設定: Mesh Renderer のマテリアルに、以下のいずれかを設定します。

| シェーダー | 説明 |
|-----------|------|
| Point Cloud/Point URP | 点として描画 |
| Point Cloud/Disk URP | ディスク（円）として描画 |
| Point Cloud/Point URP VR | VR用点描画（Single Pass Instanced対応） |
| Point Cloud/Disk URP VR | VR用ディスク描画（Single Pass Instanced対応） |

### 方法2: PointCloudRenderer (ComputeBuffer)
大量の点を効率的に描画する場合の手順です。

> ⚠️ **注意**: この方式はVR（Single Pass Instanced）では正しく描画されない場合があります。VRプロジェクトでは方法1（Meshモード）を使用してください。

インポート設定: .ply ファイルを選択し、Inspectorで Container Type を Compute Buffer に設定して Apply します。

シーン配置: GameObjectを作成し、Point Cloud Renderer コンポーネントを追加します。

データ設定: コンポーネントの Source Data スロットに、インポートした PointCloudData アセットをドラッグ＆ドロップします。

## マテリアル設定

マテリアルのInspectorから以下の設定が可能です：

| プロパティ | 説明 |
|-----------|------|
| Tint | 点群の色調整 |
| Color Order | PLYデータの色順序（RGB/BGRなど）を修正 |
| Point Size | 点のサイズ |
| Apply Distance | 距離に応じたサイズ調整 |
| Rotation | X/Y/Z軸回転（度数）でデータの向きを補正 |

## オリジナル版からの変更点
オリジナル版（jp.keijiro.pcx）からの主な変更点は以下の通りです。

- **URP 完全対応**: すべてのシェーダーを Universal Render Pipeline 用に書き換えました
- **Unity 6 対応**: 最小要件を Unity 6 (6000.0) に更新しました
- **VRシェーダー追加**: Single Pass Instanced VR対応のシェーダーを追加
- **Color Order機能**: PLYファイルの色順序（RGB/BGR等）をマテリアルから変更可能
- **Rotation機能**: シェーダー側で回転補正が可能
- **パッケージID変更**: jp.keijiro.pcx から com.atsusys.pcx-urp に変更

## 謝辞
このパッケージは、Keijiro Takahashi氏によるPcxを基にしています。コミュニティへの彼の貢献に深く感謝いたします。