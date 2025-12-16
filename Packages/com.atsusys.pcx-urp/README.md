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

### 方法1: Mesh + MeshRenderer (シンプル)
標準的なMeshとして扱いたい場合の手順です。

インポート設定: .ply ファイルを選択し、Inspectorで Container Type を Mesh に設定して Apply します。

シーン配置: GameObjectを作成し、Mesh Filter と Mesh Renderer を追加します。

マテリアル設定: Mesh Renderer のマテリアルに、以下のいずれかを設定します。

- Point Cloud/Point URP
- Point Cloud/Disk URP

### 方法2: PointCloudRenderer (ComputeBuffer)
大量の点を効率的に描画する場合の手順です。

インポート設定: .ply ファイルを選択し、Inspectorで Container Type を Compute Buffer に設定して Apply します。

シーン配置: GameObjectを作成し、Point Cloud Renderer コンポーネントを追加します。

データ設定: コンポーネントの Source Data スロットに、インポートした PointCloudData アセットをドラッグ＆ドロップします。

## オリジナル版からの変更点
オリジナル版（jp.keijiro.pcx）からの主な変更点は以下の通りです。

- URP 完全対応: すべてのシェーダーを Universal Render Pipeline 用に書き換えました。
- Unity 6 対応: 最小要件を Unity 6 (6000.0) に更新しました。
- パッケージID変更: jp.keijiro.pcx から com.atsusys.pcx-urp に変更されています。
- カラーチャンネルスワップ機能: PLYデータのRGB順序が異なる場合に対応するため、シェーダーにチャンネルスワップ機能を追加しました（RGB, BGRなど）。

## 謝辞
このパッケージは、Keijiro Takahashi氏によるPcxを基にしています。コミュニティへの彼の貢献に深く感謝いたします。

## License
This package is licensed under the Unlicense. See [LICENSE](LICENSE) for details.
