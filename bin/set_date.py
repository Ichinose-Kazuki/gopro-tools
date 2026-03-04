import argparse
import subprocess
import sys
from pathlib import Path

# コマンドライン引数の設定
parser = argparse.ArgumentParser(description="動画のExif日時を別ディレクトリのファイルからコピーします。")
parser.add_argument("base_dir", type=str, help="google_photos と exported ディレクトリが含まれるベースパス")
args = parser.parse_args()

# パスの設定
base_path = Path(args.base_dir)
target_dir = base_path / "google_photos"
source_dir = base_path / "exported"

# ディレクトリの存在確認
if not target_dir.is_dir() or not source_dir.is_dir():
    print(f"エラー: 指定されたパスにディレクトリが見つかりません。", file=sys.stderr)
    print(f"  確認先1: {target_dir}", file=sys.stderr)
    print(f"  確認先2: {source_dir}", file=sys.stderr)
    sys.exit(1)

count = 0

# 対象となる圧縮済みMP4ファイルを検索（compressは必ずあるという前提）
for compressed_path in target_dir.glob("*-compressed.*"):
    # 拡張子が mp4 (大文字・小文字問わず) でない場合はスキップ
    if compressed_path.suffix.lower() != ".mp4":
        continue

    # ベースとなるファイル名を取得
    # .stem は拡張子抜きの名前 (例: GX010017-compressed)
    base_name = compressed_path.stem.replace("-compressed", "")

    # 元ファイルのパス候補を両方作成
    source_path_lower = source_dir / f"{base_name}.mp4"
    source_path_upper = source_dir / f"{base_name}.MP4"

    # 実際に存在する方のパスを source_path として採用
    if source_path_lower.exists():
        source_path = source_path_lower
    elif source_path_upper.exists():
        source_path = source_path_upper
    else:
        print(f"スキップ: 元ファイルが見つかりません -> {base_name}.mp4 / .MP4")
        continue

    # 処理対象のファイルをリスト化する
    targets_to_process = [compressed_path]

    # dashboardファイルが存在するか確認し、あればリストに追加
    dashboard_path = target_dir / f"{base_name}-dashboard.MP4"
    if dashboard_path.exists():
        targets_to_process.append(dashboard_path)

    # リストに格納された対象ファイル（compress と、存在すれば dashboard）に対して処理を実行
    for target_path in targets_to_process:
        print(f"処理中: {target_path.name} (ソース: {source_path.name})")

        # exiftoolのコマンドを構築
        cmd = [
            "exiftool",
            "-overwrite_original",
            "-TagsFromFile", str(source_path),
            "-TrackCreateDate<MediaCreateDate",
            "-TrackModifyDate<MediaCreateDate",
            "-MediaCreateDate<MediaCreateDate",
            "-MediaModifyDate<MediaCreateDate",
            "-CreateDate<MediaCreateDate",
            "-ModifyDate<MediaCreateDate",
            str(target_path)
        ]

        # コマンドを実行
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            print(f"  完了")
        except subprocess.CalledProcessError as e:
            print(f"  エラー: {target_path.name} の処理中に問題が発生しました。")
            print(f"  詳細: {e.stderr.strip()}")

        count += 1

print("すべての処理が完了しました。")
print(f"処理数: {count}")
