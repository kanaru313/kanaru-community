{
  description = "Kanaru — music player (Flutter + Material 3)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # nixpkgs' rustc ships only the host target; Android needs the NDK targets.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        hostTriple = pkgs.stdenv.hostPlatform.rust.rustcTarget;
        # Targets cargokit builds: the Linux host plus the Android ABIs. Release
        # ships arm64-v8a, armeabi-v7a and x86_64; debug builds also add x86
        # (cargokit mirrors flutter.gradle there), hence i686.
        rustTargets = [
          hostTriple
          "aarch64-linux-android"
          "armv7-linux-androideabi"
          "x86_64-linux-android"
          "i686-linux-android"
        ];
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          targets = rustTargets;
        };

        # Native libraries the Linux desktop build links against.
        nativeLibs = with pkgs; [
          # Flutter Linux embedder (GTK)
          gtk3
          glib
          pcre2
          util-linux
          libselinux
          libsepol
          libthai
          libdatrie
          libxkbcommon
          libepoxy
          libxdmcp
          libxtst
          lerc
          libdeflate
          xz
          # media_kit (libmpv)
          mpv-unwrapped
          # flutter_secure_storage
          libsecret
          jsoncpp
          # libsecret's pkg-config file requires these (Requires.private)
          libgcrypt
          libgpg-error
          # drift
          sqlite
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            flutter

            # Linux desktop toolchain
            clang
            cmake
            ninja
            pkg-config

            # Rust (rust/ workspace via flutter_rust_bridge): one stable
            # toolchain with rustfmt, clippy, rust-analyzer and the Android
            # targets (see rustTargets).
            rustToolchain
            flutter_rust_bridge_codegen
            # flutter_rust_bridge_codegen shells out to `cargo expand`
            # (run it with RUSTC_BOOTSTRAP=1 on the stable toolchain).
            cargo-expand
            # Cargokit (flutter_rust_bridge's build glue) always calls rustup.
            # Nix has one stable toolchain and no rustup, so answer exactly the
            # three calls cargokit makes and reject everything else. The
            # installed targets are the ones baked into rustToolchain, so
            # cargokit never tries `rustup target add`.
            (writeShellScriptBin "rustup" ''
              case "$1 $2" in
                "toolchain list")
                  echo "stable-${hostTriple} (default)" ;;
                "target list")
                  if [ "$3" = "--toolchain" ] && [ "$5" = "--installed" ] || [ "$3" = "--installed" ]; then
                    printf '%s\n' ${lib.escapeShellArgs rustTargets}
                  else
                    echo "rustup shim: only 'target list --installed' is supported: $*" >&2; exit 1
                  fi ;;
                "run stable"*)
                  shift 2; exec "$@" ;;
                *)
                  echo "rustup shim: unsupported: $*" >&2; exit 1 ;;
              esac
            '')

            # Poking the MPRIS service by hand
            playerctl

            # Packaging
            appimage-run
            desktop-file-utils
            appstream
            flatpak-builder
          ] ++ nativeLibs;

          # ffigen / flutter_rust_bridge need libclang
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          # Let `flutter run` find shared libs at runtime
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeLibs;

          shellHook = ''
            export PATH="$HOME/.pub-cache/bin:$PATH"
            # Android SDK installed by Android Studio (outside Nix). Gradle and
            # cargokit find the NDK from here; nix-ld runs its prebuilt binaries.
            export ANDROID_HOME="''${ANDROID_HOME:-$HOME/Android/Sdk}"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
            echo "kanaru dev shell — $(flutter --version 2>/dev/null | head -1)" >&2
          '';
        };
      });
}
