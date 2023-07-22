{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-fly.url = "github:gmemstr/nixpkgs/flyctl-0.1.62";
  };

  outputs = { self, flake-utils, naersk, nixpkgs, nixpkgs-fly }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        pkgs-flyctl = (import nixpkgs-fly) {
          inherit system;
        };

        naersk' = pkgs.callPackage naersk {};

        defaultPackage = naersk'.buildPackage {
          src = ./.;
        };
        
        dockerContents = [
            pkgs.cacert
            pkgs.fuse3
            (pkgs.writeTextDir "/etc/litefs.yml" (builtins.readFile ./litefs.yml))
            defaultPackage
        ];
      in {
        defaultPackage = defaultPackage;

        packages.oci = pkgs.dockerTools.streamLayeredImage {
          name = "litefs-proxy-error";
          contents = dockerContents;
          config = {
            Env = [
              "PATH=/bin"
            ];
            Cmd = [ "${pkgs.litefs}/bin/litefs" "mount" "--" "/bin/litefs-proxy-error"];
          };
          tag = "latest";
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            rustc
            cargo
            rustfmt
            nixpkgs-fmt
            sccache
            clippy
            rust-analyzer
            pkgs-flyctl.flyctl
	    podman
            skopeo
            litefs
            crane
          ];

          RUSTC_WRAPPER = "sccache";
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        };
      }
    );
}
