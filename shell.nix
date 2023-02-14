with import <nixpkgs> { };

mkShell {
  # include any libraries or programs in buildInputs
  buildInputs = [
   python310Packages.selenium python310
  ];

  # shell commands to be ran upon entering shell
  shellHook = ''
    python main.py &
  '';
}
