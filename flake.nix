{
  description = "Dev shell the project";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, fenix }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          nixpkgs.overlays = [ fenix.overlays.complete ];
          devShells.default = pkgs.mkShell {
            buildInputs =  [
             pkgs.fish
             pkgs.python310Packages.selenium
             pkgs.python310
             pkgs.python310Packages.python-lsp-server
            ];
            shellHook = /*bash*/ "[ $0 = 'bash' ] && exec fish";
          };
        }
      );
}

