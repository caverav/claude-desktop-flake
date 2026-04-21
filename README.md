# claude-desktop-flake

[![CI](https://github.com/caverav/claude-desktop-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/caverav/claude-desktop-flake/actions/workflows/ci.yml)

A Nix flake that packages [Claude Desktop](https://claude.ai/download),
Anthropic's official macOS client, for both Apple Silicon
(`aarch64-darwin`) and Intel (`x86_64-darwin`).

The flake downloads the official universal `.dmg` from Anthropic's CDN,
unpacks it with `undmg`, installs `Claude.app` under `$out/Applications/`,
and drops a small shell launcher at `$out/bin/claude-desktop` so the app
is reachable from `nix run`, `nix profile install`, or any other place
that expects a `bin/` entry.

## Requirements

- macOS 12.0 (Monterey) or newer.
- [Nix](https://nixos.org/download) with flakes enabled
  (`experimental-features = nix-command flakes`).
- An Intel or Apple Silicon Mac. The underlying binary is a universal
  Mach-O, so the same source builds natively on either architecture.

## Usage

### Run once

```sh
nix run github:caverav/claude-desktop-flake
```

### Install into your user profile

```sh
nix profile install github:caverav/claude-desktop-flake#claude-desktop
```

After that, `claude-desktop` is on `$PATH` and `Claude.app` lives at
`~/.nix-profile/Applications/Claude.app`.

### As a flake input (nix-darwin)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    claude-desktop.url = "github:caverav/claude-desktop-flake";
  };

  outputs = { self, nixpkgs, nix-darwin, claude-desktop, ... }: {
    darwinConfigurations."my-mac" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ claude-desktop.overlays.default ];
          environment.systemPackages = [ pkgs.claude-desktop ];
        })
      ];
    };
  };
}
```

Because Claude Desktop is proprietary, consumers of
`overlays.default` need to allow the unfree license themselves, e.g.:

```nix
nixpkgs.config.allowUnfreePredicate =
  pkg: builtins.elem (pkgs.lib.getName pkg) [ "claude-desktop" ];
```

The flake's own outputs (`packages.*`, `apps.*`) already scope the
exemption to just this package, so `nix build` and `nix run` work
without `--impure` or `NIXPKGS_ALLOW_UNFREE=1`.
