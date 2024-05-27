{...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  services.blueman.enable = true;
  # TODO: https://nixos.wiki/wiki/Bluetooth#Using_Bluetooth_headset_buttons_to_control_media_player
  # and further
}
