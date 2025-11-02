{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # MP4 動画の圧縮
            ffmpeg
            # 動画の情報を取得
            mediainfo
            # EXIF meta 情報の読み書き
            exiftool
            # Tools to access files in the camera
            libmtp
            jmtpfs
            # For nodejs tools
            nodePackages_latest.nodejs
          ];

          shellHook = ''
            # node_modules がなければ npm ci 実行（package-lock.json 必須）
            if [ ! -d node_modules ] && [ -f package-lock.json ]; then
              echo "Installing npm dependencies with npm ci..."
              npm ci --cache $NIX_BUILD_TOP/.npm-cache
            fi

            # PATH にローカルの node_modules/.bin を追加
            export PATH=$PWD/node_modules/.bin:$PATH
          '';
        };
      }
    );
}
