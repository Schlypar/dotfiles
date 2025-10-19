# Hyprland + Quickshell Configuration

A minimal and efficient desktop configuration centered around Hyprland with Quickshell, featuring Neovim and tmux as the core workflow components.

## Core Components

- **Window Manager**: [Hyprland](https://hyprland.org/)
- **Application Launcher**: [Quickshell](https://github.com/qs-wayland/quickshell)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Editor**: [Neovim 0.11+](https://neovim.io/)
- **Shell**: Zsh
- **Terminal Multiplexer**: [tmux](https://github.com/tmux/tmux)

## Dependencies

### Required
- [Neovim 0.11+](https://github.com/neovim/neovim)
- [tmux](https://github.com/tmux/tmux)
- [tmux plugin manager](https://github.com/tmux-plugins/tpm)
- [smart tmux sessionizer](https://github.com/joshmedeski/t-smart-tmux-session-manager)
- [Quickshell](https://github.com/qs-wayland/quickshell) with qt6-5compat

### Hyprland Utilities
- hyprpolkitagent
- hyprpicker
- xdg-desktop-portal-hyprland
- xdg-desktop-portal-gtk

### Audio
- wireplumber
- pipewire
- pipewire-jack  
- pipewire-alsa
- pipewire-pulse

### System
- upower
- brightnessctl
- sox
- socat
- grim

### Media
- mpd
- mpd-mpris
- mpc

### Fonts
- ttf-bigblueterminal-nerd

## Installation

Refer to the respective repositories for installation instructions for each component. Most dependencies are available through your system's package manager.

## Features

- **Hyprland**: Modern Wayland compositor with tiling window management
- **Quickshell**: Fast application launcher for Wayland
- **Neovim + tmux**: Powerful terminal-based development environment
- **Smart session management**: Efficient workspace organization with t-smart-tmux-session-manager
- **Complete audio stack**: PipeWire with WirePlumber for modern audio handling
- **Media control**: MPD integration with MPRIS support

## Usage

After installation, the configuration provides:
- Seamless window management with Hyprland
- Quick application launching via Quickshell
- Advanced text editing with Neovim
- Terminal session persistence with tmux
- Integrated media control and audio management
