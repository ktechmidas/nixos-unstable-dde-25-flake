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

  services.getty.autologinUser = "test";

  # TODO: Enable DDE once packages are building
  # services.desktopManager.deepin.enable = true;
  # services.xserver.enable = true;
  # services.displayManager.lightdm.enable = true;

  system.stateVersion = "25.11";
}
