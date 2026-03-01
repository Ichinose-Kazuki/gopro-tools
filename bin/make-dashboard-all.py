import sys
import os
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

def should_process_gpx(gpx_path):
    """
    GPXファイルをチェックし、実行条件を満たすか判定する。
    実行しない条件:
    1. 最初の点が (0, 0)
    2. 最初の100個のデータに変化がない
    """
    try:
        tree = ET.parse(gpx_path)
        root = tree.getroot()
        
        points = []
        max_check = 100
        
        # XMLから lat, lon を持つ要素を最大100個抽出
        for element in root.iter():
            if 'lat' in element.attrib and 'lon' in element.attrib:
                try:
                    lat = float(element.attrib['lat'])
                    lon = float(element.attrib['lon'])
                    points.append((lat, lon))
                    
                    if len(points) >= max_check:
                        break
                except ValueError:
                    continue
        
        # データが空の場合はスキップ
        if not points:
            return False, "No data points found"

        # 以下の条件で GPS がロックされていない動画をすべて弾けるかわからないが、GPS のロック状態のメタデータが取得できていないので完璧な確認は諦める
        # 条件(1): 最初の lat, lon の値が 0, 0 である
        first_lat, first_lon = points[0]
        if first_lat == 0.0 and first_lon == 0.0:
            return False, "Starts with (0.0, 0.0)"

        # 条件(2): 100個（またはそれ以下）見て、全く変化がない
        # set() を使って重複を排除し、要素数が1なら変化なしとみなす
        if len(set(points)) == 1:
            return False, f"No movement detected in first {len(points)} points"

        # 条件をクリアした場合
        return True, "Valid GPS data"

    except Exception as e:
        return False, f"Error reading GPX: {e}"

def main():
    if len(sys.argv) < 2:
        print("Usage: python process_dirs_strict.py <base_directory>")
        sys.exit(1)

    base_dir = Path(sys.argv[1])

    if not base_dir.exists():
        print(f"Error: Directory '{base_dir}' not found.")
        sys.exit(1)

    for item in base_dir.iterdir():
        if item.is_dir():
            gpx_files = list(item.glob('*.gpx'))
            
            if not gpx_files:
                continue

            gpx_file = gpx_files[0]
            
            # 条件判定
            should_run, reason = should_process_gpx(gpx_file)
            
            if should_run:
                target_dir = str(item)
                # bin/make-dashboard.sh は実行場所からの相対パスと仮定
                command = ["bash", "bin/make-dashboard.sh", target_dir]
                
                print(f"[EXEC] {item.name}: {reason}")
                try:
                    subprocess.run(command, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Command failed for {target_dir}: {e}", file=sys.stderr)
            else:
                print(f"[SKIP] {item.name}: {reason}")

if __name__ == "__main__":
    main()

