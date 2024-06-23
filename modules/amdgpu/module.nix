{
  pkgs,
  config,
  lib,
  ...
}:

let
  this = config.custom.amdgpu;
in

{
  options.custom.amdgpu = {
    kernelModule = {
      patches = lib.mkOption {
        type = with lib.types; listOf path;
        default = [ ];
        description = ''
          Patches to apply to the kernel for the `amdgpu` kernel module build.

          This is intended for applying small patches concerning only the
          `amdgpu` module's internals without needing to rebuild the entire
          kernel.

          The patches are applied to the entire kernel tree but only the
          `amdgpu` module will actually be built and used. You should therefore
          not touch anything outside of `drivers/gpu/drm/amd/amdgpu` using the
          patches as those modifications will not be present in the actual
          kernel you will be running which might cause undefined and likely
          erroneous behaviour.
          Use {option}`boot.kernelPatches` instead for such cases.

          A reboot is required for the patched module to be loaded.
        '';
        example = lib.literalExpression ''
          [
            (pkgs.fetchpatch2 {
              url = "https://lore.kernel.org/lkml/20240610-amdgpu-min-backlight-quirk-v1-1-8459895a5b2a@weissschuh.net/raw";
              hash = "";
            })
          ]
        '';
      };
    };
  };

  config = {
    boot.extraModulePackages = lib.mkIf (this.kernelModule.patches != [ ]) [
      (pkgs.callPackage ./kernel-module.nix {
        inherit (config.boot.kernelPackages) kernel;
        inherit (this.kernelModule) patches;
      })
    ];
  };
}
