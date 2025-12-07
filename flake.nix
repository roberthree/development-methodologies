{
  inputs = {
    nixpkgs.url = "nixpkgs/25.05";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              cspell = {
                enable = true;
                args = [
                  "--no-must-find-files"
                ];
              };

              nixfmt-rfc-style.enable = true;

              markdownlint = {
                enable = true;
                entry = "${pkgs.nodePackages.markdownlint-cli2}/bin/markdownlint-cli2";
                files = "\\.qmd$";
              };

              prettier.enable = true;
            };
          };
        };

        formatter =
          let
            inherit (self.checks.${system}.pre-commit-check.config) package configFile;
            script = ''
              ${package}/bin/pre-commit run --all-files --config ${configFile}
            '';
          in
          pkgs.writeShellScriptBin "pre-commit-run" script;

        packages = {
          book = pkgs.stdenv.mkDerivation {
            pname = "book";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = with pkgs; [
              mdbook
            ];
            buildPhase = ''
              mdbook build -d "$out" ./book/
            '';
            installPhase = "true";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "development-methodologies";

          inputsFrom = [
            self.checks.${system}.pre-commit-check
          ];

          packages = with pkgs; [
            mdbook
            quarto
          ];

          shellHook = ''
            echo "Development shell for improving the \"Development Methodologies\" book"
          '';
        };
      }
    );
}
