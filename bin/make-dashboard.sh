#/usr/bin/env bash

set -eux

# 1. ディレクトリ引数の確認
if [ -z "$1" ]; then
    echo "使用法: $0 <処理対象のディレクトリ>"
    exit 1
fi

VIDEO_DIR="$1"
VIDEO_DIR_SAFE="$( cd $VIDEO_DIR && pwd )"
VIDEO_DIR_BASENAME=$(basename $VIDEO_DIR_SAFE)

# 2. ディレクトリの存在と有効性を確認
if [ ! -d "$VIDEO_DIR" ]; then
    echo "エラー: ディレクトリ '$VIDEO_DIR' が見つかりません。"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo "--- '$VIDEO_DIR' を処理します ---"

"${PARENT_DIR}/.venv/bin/gopro-dashboard.py" --gpx "${VIDEO_DIR_SAFE}/${VIDEO_DIR_BASENAME}-GPS5.gpx" --use-gpx-only --layout-xml "${PARENT_DIR}/dashboard/layout-1920x1080.xml" --units-speed kph --units-altitude meter --units-distance meter "${VIDEO_DIR_SAFE}/${VIDEO_DIR_BASENAME}-compressed.MP4" "${VIDEO_DIR_SAFE}/${VIDEO_DIR_BASENAME}-dashboard.MP4"

echo "--- 処理が完了しました ---"
