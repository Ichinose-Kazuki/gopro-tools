# gopro-tools
- GoPro で撮影した MP4 動画を、GoPro 特有のメタデータを維持しながら圧縮する。
- GPS 情報を重ねた動画を作成する。

## 使い方
- ディレクトリの中の全 MP4 ファイルの名前を撮影日時に変更
  ```shell
  .venv/bin/gopro-rename.py --yes --dirs videos [ディレクトリへのパス]
  ```
- ディレクトリの中の全 MP4 ファイルを圧縮
  ```shell
  bash compress.sh [ディレクトリへのパス]
  ```
- GPS 情報を重ねて表示した動画を元動画と同じディレクトリに作成
  ```shell
  bash make-dashboard.sh [動画ファイルへのパス]
  ```

## 圧縮率
- 元動画: 144M
- 圧縮後動画: 27M
- gpx メタデータ: 104K
- json メタデータ: 2.6M (gpx とかぶるデータを消しても 0.1M しか消えない（当たり前）)

## GPX ファイルの利用方法
- https://github.com/time4tea/gopro-dashboard-overlay を使う
  - 引数: https://github.com/time4tea/gopro-dashboard-overlay/tree/main/docs/bin
  - 実行例
    ```shell
    .venv/bin/gopro-dashboard.py --gpx output.gpx --use-gpx-only --layout-xml layout-1920x1080.xml --units-speed kph --units-altitude meter --units-distance meter videos/output_normal.mp4 output-dashboard.mp4
    ```

