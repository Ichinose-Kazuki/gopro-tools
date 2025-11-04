#/usr/bin/env bash

set -eux

# 1. ディレクトリ引数の確認
if [ -z "$1" ]; then
    echo "使用法: $0 <処理対象のディレクトリ>"
    exit 1
fi

TARGET_DIR="$1"

# 2. ディレクトリの存在と有効性を確認
if [ ! -d "$TARGET_DIR" ]; then
    echo "エラー: ディレクトリ '$TARGET_DIR' が見つからないか、ディレクトリではありません。"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo "--- ディレクトリ '$TARGET_DIR' 内の .MP4 ファイルを処理します ---"

# 3. .MP4 ファイルのループ処理
# $TARGET_DIR/*.MP4 で指定ディレクトリ直下の .MP4 ファイルを検索
# スペースを含むファイル名も適切に処理するためにクォート ("...") を使用
for file in "$TARGET_DIR"/*.MP4; do
    # 4. ファイルの存在確認 (マッチするファイルがない場合に glob がそのままの文字列として残るのを防ぐ)
    if [ -f "$file" ]; then
        echo "処理対象ファイル: $file"

        FILE_NO_EXT="${$file%.*}"

        mkdir "$FILE_NO_EXT"

        # Trying to remove tmcd stream, but fails possibly due to ffmpeg's bug
        ffmpeg -i "${TARGET_DIR}/$file" -map 0:v:m:vendor_id -map 0:a -c:v:m:vendor_id libx265 -crf 23 -c:a copy "${TARGET_DIR}/${FILE_NO_EXT}/${FILE_NO_EXT}-compressed.MP4"

        # Extract metadata
        node "${PARENT_DIR}/extract_json.js" "${TARGET_DIR}/$file" "${TARGET_DIR}/${FILE_NO_EXT}/${FILE_NO_EXT}-metadata.json"
        node "${PARENT_DIR}/extract_gpx.js" "${TARGET_DIR}/$file" "${TARGET_DIR}/${FILE_NO_EXT}/${FILE_NO_EXT}-GPS5.gpx"

        # DELETE the original file
        rm "${TARGET_DIR}/$file"
    fi
done

echo "--- 処理が完了しました ---"


