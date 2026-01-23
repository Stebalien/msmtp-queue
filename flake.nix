{
  description = "Improved MSMTP mail queuing scripts, with systemd units";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      eachSystem = nixpkgs.lib.genAttrs [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
      ];
      mkPackages = pkgs: rec {
        msmtpq = pkgs.resholve.mkDerivation {
          pname = "msmtpq";
          version = "1.0.0";
          src = ./.;
          strictDeps = true;
          nativeBuildInputs = with pkgs; [
            gnumake
            m4
          ];

          # Resholved seems to move these already?
          # I think there's a bug somewhere.
          dontMoveSystemdUserUnits = true;

          installPhase = ''
            mkdir -p $out/bin/
            install -m755 msmtpq msmtpq-flush msmtpq-queue $out/bin
            install -Dm644 -t "$out/lib/systemd/user/" systemd/*
          '';

          postResholve = ''
            substituteInPlace "$out/lib/systemd/user/msmtp-queue.service" \
              --replace-fail '/usr/local/bin/msmtpq-flush' "$out/bin/msmtpq-flush"
          '';

          solutions = {
            msmtpq = {
              interpreter = "${pkgs.bash}/bin/bash";
              scripts = [
                "bin/msmtpq"
                "bin/msmtpq-flush"
                "bin/msmtpq-queue"
              ];
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
        };
        default = msmtpq;
      };
    in
    {
      packages = eachSystem (system: mkPackages nixpkgs.legacyPackages.${system});
      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      overlays.default = final: prev: {
        inherit (mkPackages final) msmtpq;
      };
      nixosModules.default =
        {
          lib,
          config,
          pkgs,
          ...
        }:
        let
          cfg = config.services.msmtpq;
        in
        {
          options.services.msmtpq = {
            enable = lib.mkEnableOption "enable the systemd units for msmtpq";
            package = lib.mkPackageOption (mkPackages pkgs) "msmtpq" { };
          };
          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
            systemd = {
              packages = [ cfg.package ];
              user.paths.msmtp-queue.wantedBy = [ "paths.target" ];
              user.timers.msmtp-queue.wantedBy = [ "timers.target" ];
            };
          };
        };
    };
}
