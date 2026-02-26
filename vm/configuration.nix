# QEMU VM configuration for testing DDE
{ config, pkgs, lib, ... }:

{
  # VM settings (these go under vmVariant for nixos-rebuild build-vm)
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 8192;
      resolution = { x = 1920; y = 1080; };
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
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
  };

  # Enable DDE
  services.desktopManager.deepin.enable = true;

  # Display manager — use LightDM with autologin
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeter.enable = false;
  };
  services.displayManager.defaultSession = "deepin";
  services.displayManager.autoLogin = {
    enable = true;
    user = "test";
  };

  # Allow test user passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}
