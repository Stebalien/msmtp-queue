{
  description = "Improved MSMTP mail queuing scripts, with systemd units";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } (
    { moduleWithSystem, ... }:
    {
      systems = [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
      ];
      imports = [ flake-parts.flakeModules.easyOverlay ];
      perSystem = { config, system, lib, pkgs, ...}:
        let
          msmtpq = (pkgs.resholve.mkDerivation {
            pname = "msmtpq";
            version = "1.0.0";
            src = ./.;
            strictDeps = true;
            nativeBuildInputs = with pkgs; [ gnumake m4 ];

            installPhase = ''
              mkdir -p $out/bin/
              install -Dm755 msmtpq msmtpq-flush msmtpq-queue $out/bin
              install -Dm644 -t "$out/share/systemd/user/" systemd/*
            '';

            solutions = {
              msmtpq = {
                interpreter = "${pkgs.bash}/bin/bash";
                scripts = [ "bin/msmtpq" "bin/msmtpq-flush" "bin/msmtpq-queue" ];
                inputs = with pkgs; [
                  util-linux
                  coreutils
                  findutils
                  gnused
                  (msmtp.override { withScripts = false; })
                ];
                execer = [
                  "cannot:${pkgs.util-linux}/bin/flock"
                ];
              };
            };
          }).overrideAttrs (old: {
            preFixup = ''
              substituteInPlace "$out/share/systemd/user/msmtp-queue.service" \
                --replace-fail '/usr/local/bin/msmtpq-flush' "$out/bin/msmtpq-flush"
            '' + old.preFixup;
          });
        in rec {
          packages = {
            inherit msmtpq;
            default = packages.msmtpq;
          };
          overlayAttrs = {
            inherit (config.packages) msmtpq;
          };
        };
      flake.nixosModules.default = moduleWithSystem (
        perSystem@{pkgs, self', ... }:
        nixos@{lib, config, ... }:
        let
          cfg = config.services.msmtpq;
        in
        {
          options.services.msmtpq = {
            enable = lib.mkEnableOption "enable the systemd units for msmtpq";
            package = lib.mkPackageOption self'.packages "msmtpq" { };
          };
          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
            systemd = {
              packages = [ cfg.package ];
              user.paths.msmtp-queue.wantedBy = [ "paths.target" ];
              user.timers.msmtp-queue.wantedBy = [ "timers.target" ];
            };
          };
        });
    });
  }
