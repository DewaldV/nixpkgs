{ config, lib, pkgs, ... }:
let
  cfg = config.services.rvu-kolide;

  inherit (lib) mkIf mkEnableOption mkOption literalExample types;
in {
  options.services.rvu-kolide = {
    enable = mkEnableOption "Enable Kolide Agent";

    package = mkOption {
      type = types.package;
      default = pkgs.rvu-kolide;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.rvu-kolide = {
      description = "The Kolide Launcher";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "syslog.service" ];

      restartIfChanged = true;

      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${cfg.package}/bin/launcher -config ${cfg.package}/etc/kolide-k2/launcher.flags";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
