{
  description = "Creatively named custom bar for Hyprland";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    astal,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = astal.lib.mkLuaPackage {
      inherit pkgs;
      name = "hyprbar"; # how to name the executable
      src = ./hyprbar; # should contain init.lua

      # add extra glib packages or binaries
      # TODO: luajit this bad boy UP
      extraPackages = [
        astal.packages.${system}.battery
        astal.packages.${system}.hyprland
        astal.packages.${system}.mpris
        astal.packages.${system}.network
        astal.packages.${system}.tray
        astal.packages.${system}.wireplumber
        pkgs.dart-sass
      ];
    };
  };
}
