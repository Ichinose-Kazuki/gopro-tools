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

TARGET_DIR_SAFE="$( cd "${TARGET_DIR}" && pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo "--- ディレクトリ '$TARGET_DIR_SAFE' 内の .MP4 ファイルを処理します ---"

# 3. .MP4 ファイルのループ処理
# $TARGET_DIR_SAFE/*.MP4 で指定ディレクトリ直下の .MP4 ファイルを検索
# スペースを含むファイル名も適切に処理するためにクォート ("...") を使用
for file_fullpath in "$TARGET_DIR_SAFE"/*.MP4; do
    # 4. ファイルの存在確認 (マッチするファイルがない場合に glob がそのままの文字列として残るのを防ぐ)
    if [ -f "$file_fullpath" ]; then
        echo "処理対象ファイル: $file_fullpath"

        FILE=$(basename $file_fullpath)
        FILE_NO_EXT="${FILE%.*}"

        mkdir -p "${TARGET_DIR_SAFE}/${FILE_NO_EXT}"

        # Trying to remove tmcd stream, but fails possibly due to ffmpeg's bug
        ffmpeg -i "${TARGET_DIR_SAFE}/${FILE}" -map 0:v:m:vendor_id -map 0:a -c:v:m:vendor_id libx265 -crf 23 -c:a copy "${TARGET_DIR_SAFE}/${FILE_NO_EXT}/${FILE_NO_EXT}-compressed.MP4"

        # workaround for videos > 2 GiB: https://github.com/JuanIrache/gopro-telemetry/issues/63#issuecomment-577925017
        # this doesn't work: https://github.com/ZainUlMustafa/GoPro-Telemetry-Tests/blob/main/TelemetryTests/alt_index.js
        ffmpeg -i "${TARGET_DIR_SAFE}/${FILE}" -vf scale=320:-1 -map 0:0 -map 0:1 -map 0:3 -codec:v mpeg2video -codec:d copy -codec:a copy -y "${TARGET_DIR_SAFE}/${FILE_NO_EXT}-small.MP4"

        # Extract metadata
        node "${PARENT_DIR}/extract/extract_json.js" "${TARGET_DIR_SAFE}/${FILE_NO_EXT}-small.MP4" "${TARGET_DIR_SAFE}/${FILE_NO_EXT}/${FILE_NO_EXT}-metadata.json"
        node "${PARENT_DIR}/extract/extract_gpx.js" "${TARGET_DIR_SAFE}/${FILE_NO_EXT}-small.MP4" "${TARGET_DIR_SAFE}/${FILE_NO_EXT}/${FILE_NO_EXT}-GPS5.gpx"

        # DELETE the small file and the original file
        rm "${TARGET_DIR_SAFE}/${FILE_NO_EXT}-small.MP4"
        rm "${TARGET_DIR_SAFE}/${FILE}"
    fi
done

echo "--- 処理が完了しました ---"


