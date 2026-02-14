import sys
import os
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

def has_valid_coordinates(gpx_path):
    """
    GPXファイルを解析し、(0, 0) 以外の有効な座標が含まれているか確認する
    """
    try:
        # XMLとしてパース
        tree = ET.parse(gpx_path)
        root = tree.getroot()
        
        # 名前空間を気にせず、すべての要素を再帰的に走査
        for element in root.iter():
            # lat, lon 属性を持っているか確認
            if 'lat' in element.attrib and 'lon' in element.attrib:
                try:
                    lat = float(element.attrib['lat'])
                    lon = float(element.attrib['lon'])
                    
                    # latとlonが両方とも0でなければ有効とみなす
                    # (GoPro等はGPSロック前に 0.0, 0.0 を記録することがあるため)
                    # この判定方法は正しくないことがある。ちゃんと判定するためのメタデータが抽出できていないので、とりあえずこれでいいとする。
                    if lat != 0.0 or lon != 0.0:
                        return True
                    if lat == 0.0 or lon == 0.0:
                        return False
                except ValueError:
                    continue
                    
        return False
    except Exception as e:
        print(f"Error reading {gpx_path}: {e}", file=sys.stderr)
        return False

def main():
    # 引数チェック
    if len(sys.argv) < 2:
        print("Usage: python process_dirs.py <base_directory>")
        sys.exit(1)

    base_dir = Path(sys.argv[1])

    if not base_dir.exists():
        print(f"Error: Directory '{base_dir}' not found.")
        sys.exit(1)

    # ベースディレクトリ内のアイテムを走査
    for item in base_dir.iterdir():
        if item.is_dir():
            # ディレクトリ内で .gpx ファイルを探す
            gpx_files = list(item.glob('*.gpx'))
            
            if not gpx_files:
                continue

            # 最初に見つかったGPXファイルを使用（構造上1つと仮定）
            gpx_file = gpx_files[0]
            
            # 有効な座標があるかチェック
            if has_valid_coordinates(gpx_file):
                target_dir = str(item)
                command = ["bash", "bin/make-dashboard.sh", target_dir]
                
                print(f"Valid GPS found in {item.name}. Executing: {' '.join(command)}")
                
                # コマンド実行
                try:
                    subprocess.run(command, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Command failed for {target_dir}: {e}", file=sys.stderr)
            else:
                print(f"Skipping {item.name} (GPS data implies 0,0 or invalid)")

if __name__ == "__main__":
    main()

