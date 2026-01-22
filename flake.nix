{
  description = "Improved MSMTP mail queuing scripts, with systemd units";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      eachSystem = nixpkgs.lib.genAttrs [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
      ];
    in
    {
      packages = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
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
        in
        {
          inherit msmtpq;
          default = msmtpq;
        }
      );

      overlays.default = final: prev: {
        inherit (self.packages.${final.system}) msmtpq;
      };

      nixosModules.default = { lib, config, pkgs, ... }:
        let
          cfg = config.services.msmtpq;
        in
        {
          options.services.msmtpq = {
            enable = lib.mkEnableOption "enable the systemd units for msmtpq";
            package = lib.mkPackageOption self.packages.${pkgs.system} "msmtpq" { };
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
