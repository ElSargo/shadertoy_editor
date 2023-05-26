{
  description = "Use a native editor for shadertoy.com";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils}:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          devShells.default = pkgs.mkShell {
            buildInputs =  with pkgs; [
             firefox
             python310Packages.selenium
             python310
             python310Packages.python-lsp-server
            ];
          };
        }
      );
}

