{ pkgs ? import <nixpkgs> {} }:

with pkgs;
mkShell {
  # Add system dependencies
  packages = [
    clang
    mold
    gdb
    nim2
    nimble-unwrapped
  ];

  # Bash statements that are executed by nix-shell
  shellHook = ''
    export CC="clang"
    export CXX="clang++"
  '';
}