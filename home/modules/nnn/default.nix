# TODO: decompose programs.nnn.extraPackages into separate plugin dependencies
# TODO: just like with helix - using lib.mkMerge
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.nnn;
in
{
  options.custom.nnn = {
    enable = lib.mkEnableOption "nnn file manager";
  };
  # config.programs = lib.mkIf cfg.enable {
  config = lib.mkIf cfg.enable {
    programs.nnn = {
      enable = true;
      extraPackages = with pkgs; [
        zip
        unzip

        # ffmpeg
        # ffmpegthumbnailer
        # (pkgs.writeShellScriptBin "catimg" ''wezterm imgcat "$@"'')

        xdragon

        # --- preview-tui ---
        less
        tree
        mediainfo
        mktemp
        unzip
        gnutar
        man
        atool
        bat
        # imagemagick
        ffmpegthumbnailer
        ffmpeg
        poppler
        gnome-epub-thumbnailer
        fontpreview
        djvulibre
        glow
        elinks
      ];
      package = pkgs.nnn.override { withNerdIcons = true; };
      plugins = {
        mappings = {
          d = "dragdrop";
          # v = "imgview";
          p = "preview-tui";
        };
        src =
          (pkgs.fetchFromGitHub {
            owner = "jarun";
            repo = "nnn";
            rev = "v4.9"; # TODO: update from time to time or switch to flake
            # sha256 = pkgs.lib.fakeSha256;
            sha256 = "g19uI36HyzTF2YUQKFP4DE2ZBsArGryVHhX79Y0XzhU=";
          })
          + "/plugins";
      };
    };
    programs.bash = lib.mkIf config.programs.bash.enable { bashrcExtra = builtins.readFile ./.bashrc; };
    home.sessionVariables = {
      NNN_FIFO = "/tmp/nnn.fifo";
    };
  };
}
