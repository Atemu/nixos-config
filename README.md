# Atemu's NixOS configs

## Structure

- [`configs`](./configs/) contain the configs of my various hosts:
  - HEPHAISTOS is a desktop gaming computer and workstation
  - SOTERIA is my home server, hosting various services and holding my hot data
  - THESEUS is my portable laptop computer (a https://frame.work laptop, get it?)
  - PLATON is a portable pen tablet convertible laptop
- [`hardware`](./hardware/) contain configuration specific to certain hardware systems of mine. The individual `configs` include them, depending on which machines they're used on.
- [`modules`](./modules/) contain NixOS modules for configuring certain aspects of my system. These are standardised to only have an effect when their `enable` option is set.
- [`common.nix`](./common.nix) contains config common across all of my hosts regardless of its purpose; enables some of my custom modules by default via `custom.enable`.

## Usage

I deploy my systems using [colmena](https://github.com/zhaofengli/colmena/). See my [colmena configuration](./hive.nix) for the details.

Alternatively, it is also possible to:

    nix-build -A HOSTNAME.system

or

    nixos-rebuild build -I nixos-config=configs/HOSTNAME/default.nix

Additionally, a symlink can be created from `./current-config.nix` to a host's `default.nix` allowing you to pass just this directory to `nixos-rebuild`.

## Secrets

Some modules utilise "secret" values such as my personal domain name containing my clear name or my ACME email which I do not wish to publish here. These must be given in a `./secrets.nix` that is explicitly not checked into git.

## Flakes?

No.

## License

This code is licensed under the [MIT license](./LICENSE) unless specified otherwise. Feel free to re-use or bring it into upstream projects.
