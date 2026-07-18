{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.gaming.vr;
in

{
  options.custom.gaming.vr = {
    enable = lib.mkEnableOption "my VR setup";
    steamvr.unprivilegedHighPriorityQueue = lib.mkEnableOption ''
      whether to allow any unprivileged process to create a high priority queue.
      This is a workaround required for SteamVR's asynchronous projection to
      function properly within the Nix Steam FHS container.

      Note that enabling this has security implications as it'd allow any
      process to deny service of the system (DOS). This should however not be
      a critical vulnerability on a typical single-user desktop machine.
    '';
    monado = {
      enable = lib.mkEnableOption "my monado compositor setup";
    };
  };

  config =
    lib.mkIf this.enable
    <| lib.mkMerge [
      (lib.mkIf (this.monado.enable) {
        services.monado.enable = true;
        services.monado.highPriority = true;
        services.monado.defaultRuntime = true;
        systemd.user.services.monado.environment = {
          # Use SteamVR LH for tracking instead of libsurvive. It's not quite
          # there yet and this way I at least have a sensible compositor.
          STEAMVR_LH_ENABLE = lib.boolToString true;
          # It doesn't discover this on its own because I only bind-mount this
          # in steam's fhsenv
          STEAMVR_PATH = "/Volumes/Games/SteamVR/";

          # Not 140 as recommended basically everywhere as that's quite expensive, actually.
          # TODO figure out how to do this per-app
          XRT_COMPOSITOR_SCALE_PERCENTAGE = "120";
          XRT_COMPOSITOR_COMPUTE = "1";

          # Stop monado after a few seconds of inactivity. (Not
          # IPC_EXIT_ON_DISCONNECT because that quits immediately.)
          IPC_EXIT_WHEN_IDLE = lib.boolToString true;
        };
        custom.gaming.steam.arguments.extraEnv = {
          # Allow steam runtime to use a runtime other than SteamVR
          PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
          # Force xrizer to be the default OpenVR runtime. I must do it this way
          # because Steam overwrites the `openvrpaths.vrpath` file on every
          # start and I'd need to get the path to xrizer somehow anyway.
          VR_OVERRIDE = "${pkgs.xrizer}/lib/xrizer/";
          # For quick access in individual games' launch args
          VR_OPENCOMPOSITE = "${pkgs.opencomposite}/lib/opencomposite/";
        };
      })
      (lib.mkIf this.steamvr.unprivilegedHighPriorityQueue {
        custom.amdgpu.kernelModule.patches = [
          (pkgs.fetchpatch2 {
            url = "https://github.com/Frogging-Family/community-patches/raw/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch";
            hash = "sha256-1wUIeBrUfmRSADH963Ax/kXgm9x7ea6K6hQ+bStniIY=";
          })
        ];
      })
    ];

}
