# Setup
1. Run `install_things.sh` from this repository root.
2. The script creates these symlinks (with replace confirmation prompts):
   - `~/.config/hypr` -> `<repo>/hypr`
   - `~/.config/waybar` -> `<repo>/waybar`
3. Set up audio for hdmi if does not show up in `wpctl status`
    - [Follow this guide](https://askubuntu.com/questions/1256043/no-sound-on-hdmi-ubuntu-20-04)
    - `aplay -l` to get list of hardware playback devices
    - `speaker-test --channels 2 --test wav --device hw:[card],[device]` to go through each device and see which one maps to external speaker
    - `pactl load-module module-alsa-sink device=hw:[card],[device]` to have this device show up in `wpctl status` 
    - `wpctl set-default {sinks id}`
    - You could also make a service on startup (~/.config/systemd/user) and that all these




# Edit ~/.config/hypr/hyprland.conf
1. Turn on natural scroll in `input.touchpad.natural_scroll`
2. Add custom bindings
   ```
   bind = $mainMod, F, fullscreen, 0
   ```
3. Change monitor scale to 1.67


# Framework 13 specific
1. Fix multimedia buttons (light, audio controls), [refer to this thread](https://community.frame.work/t/fn-key-media-keys-broken-in-arch/56880)
    - Install these dependencies
        - Brightness: `sudo pacman -S brightnessctl (Arch)
        - Audio: `sudo pacman -S wireplumber (Pipewire)
    - Add these to your ~/.config/hypr/hyprland.conf if not already configured (Most of the time it should already be there): 
    ```
    # --- Framework 13 Special Keys ---

    # Screen Brightness
    bindel = , XF86MonBrightnessUp, exec, brightnessctl set +5%
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

    # Audio Volume
    bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindel = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

    # Microphone Mute (LED often handles itself, but binding toggle is good)
    bindl = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    ```


# Other customizations
1. Navigate to `/etc/makepkg.conf` and edit `MAKEFLAGS="-j{threads on device}"`. For my laptop its 2 threads/core, 6 cores => 12 threads
