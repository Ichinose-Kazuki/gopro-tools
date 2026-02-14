import sys
import os
import shutil
from pathlib import Path

def main():
    # 引数チェック
    if len(sys.argv) < 2:
        print("Usage: python gather_videos.py <base_directory>")
        sys.exit(1)

    base_dir = Path(sys.argv[1]).resolve()

    if not base_dir.exists():
        print(f"Error: Directory '{base_dir}' not found.")
        sys.exit(1)

    # 保存先ディレクトリの作成 (base_dir/google_photos)
    dest_dir = base_dir / "google_photos"
    dest_dir.mkdir(exist_ok=True)
    print(f"Destination: {dest_dir}")

    # コピーした数のカウンタ
    count = 0

    # base_dir 以下を再帰的に検索
    # rglob('*') で全ファイルを走査し、拡張子でフィルタリング
    for file_path in base_dir.rglob('*'):
        
        # ファイルでない、または保存先ディレクトリ内のファイルはスキップ
        if not file_path.is_file() or dest_dir in file_path.parents:
            continue

        # 拡張子が .mp4 (大文字小文字区別なし) の場合
        if file_path.suffix.lower() == '.mp4' or file_path.suffix.lower() == '.jpg':
            target_path = dest_dir / file_path.name

            # 既に同名のファイルが存在する場合はスキップ（上書きしたい場合はここを変更）
            if target_path.exists():
                print(f"Skipping (exists): {file_path.name}")
                continue

            try:
                # copy2 を使うことでメタデータ（作成日時など）を保持してコピー
                shutil.copy2(file_path, target_path)
                print(f"Copied: {file_path.name}")
                count += 1
            except Exception as e:
                print(f"Error copying {file_path.name}: {e}", file=sys.stderr)

    print(f"--- Completed. {count} files copied. ---")

if __name__ == "__main__":
    main()

