{
  description = "Dev Environment for Weather Forecasting";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    unstable,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };
    uPkgs = import unstable {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };
    buildToolsVersion = "33.0.1";
    androidComposition = pkgs.androidenv.composeAndroidPackages {
      buildToolsVersions = [
        buildToolsVersion
        "35.0.0"
      ];
      platformVersions = [
        "33"
        "35"
      ];
      abiVersions = ["armeabi-v7a" "arm64-v8a"];
      extraLicenses = [
        "android-googletv-license"
        "android-sdk-arm-dbt-license"
        "android-sdk-license"
        "android-sdk-preview-license"
        "google-gdk-license"
        "intel-android-extra-license"
        "intel-android-sysimage-license"
        "mips-android-sysimage-license"
      ];
    };
    # Fix the has mismatch using overlay
    androidSdk = androidComposition.androidsdk;
  in {
    devShells.${system}.default =
      pkgs.mkShell
      {
        name = "flutter-shell";
        ANDROID_SDK_ROOT = "${toString ./android-sdk}";
        ANDROID_HOME = "${toString ./android-sdk}";
        JAVA_HOME = "${pkgs.jdk17}";
        PKG_CONFIG_PATH = "${pkgs.sysprof}/lib/pkgconfig";

        buildInputs = with uPkgs; [
          flutter
          androidSdk
          jdk17
          firebase-tools
          cmake
          ninja
          pkg-config
          glib
          gtk3
          graphite2
          libnotify
          gdk-pixbuf
          sysprof
          atkmm
          watchexec
          fswatch
        ];

        shellHook = ''
          # Ensure Android SDK is set up in a writable directory
          export ANDROID_SDK_ROOT=$(pwd)/android-sdk
          export ANDROID_HOME=$ANDROID_SDK_ROOT

          # Copy SDK files to writable directory if not already present
          if [ ! -d "$ANDROID_SDK_ROOT" ]; then
            mkdir -p "$ANDROID_SDK_ROOT"
            cp -r ${androidSdk}/libexec/android-sdk/* "$ANDROID_SDK_ROOT/"
            chmod -R u+w "$ANDROID_SDK_ROOT"
          fi

          # Generate local.properties for Gradle
          echo "sdk.dir=$ANDROID_SDK_ROOT" > ./android/local.properties
        '';
      };
  };
}
