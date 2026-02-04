{
  description = "Typeset documents with LaTeX and Typst";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-full
            latexmk;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            # LaTeX
            tex
            pkgs.texlab           # LSP

            # Typst
            pkgs.typst
            pkgs.tinymist         # LSP

            # Tools
            pkgs.sioyek           # PDF viewer
            pkgs.just             # Task runner
          ];

          shellHook = ''
            echo "Typeset environment loaded"
            echo "  LaTeX: latexmk, texlab (LSP)"
            echo "  Typst: typst, tinymist (LSP)"
            echo "  Tools: sioyek, just"
          '';
        };
      }
    );
}
