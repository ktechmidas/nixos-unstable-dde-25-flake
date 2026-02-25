# QEMU VM configuration for testing DDE
{ config, pkgs, lib, ... }:

{
  # Basic VM settings
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      qemu.options = [
        "-vga virtio"
      ];
    };
  };

  # Basic system config
  networking.hostName = "dde-test";
  time.timeZone = "UTC";

  users.users.test = {
    isNormalUser = true;
    password = "test";
    extraGroups = [ "wheel" "video" "audio" ];
  };

  # Enable DDE
  services.desktopManager.deepin.enable = true;

  # Display manager
  services.displayManager.defaultSession = "deepin";
  services.displayManager.autoLogin = {
    enable = true;
    user = "test";
  };

  system.stateVersion = "25.11";
}
