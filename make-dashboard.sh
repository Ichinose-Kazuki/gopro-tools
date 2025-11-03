#/usr/bin/env bash

set -eux

# 1. ファイル引数の確認
if [ -z "$1" ]; then
    echo "使用法: $0 <処理対象のファイル>"
    exit 1
fi

VIDEO_PATH="$1"
VIDEO_PATH_NO_EXT="${$VIDEO_PATH%.*}"

# 2. ファイルの存在と有効性を確認
# -f は指定されたパスが通常ファイルであることをチェックします
if [ ! -f "$VIDEO_PATH" ]; then
    echo "エラー: ファイル '$VIDEO_PATH' が見つからないか、通常ファイルではありません。"
    exit 1
fi

echo "--- '$VIDEO_PATH' を処理します ---"

.venv/bin/gopro-dashboard.py --gpx "${VIDEO_PATH_NO_EXT}.gpx" --use-gpx-only --layout-xml layout-1920x1080.xml --units-speed kph --units-altitude meter --units-distance meter "$VIDEO_PATH" "${VIDEO_PATH_NO_EXT}-dashboard.MP4"

echo "--- 処理が完了しました ---"
