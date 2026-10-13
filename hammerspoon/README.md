# Hammerspoon

macOS only. This directory is symlinked to `~/.hammerspoon`, and `mise bootstrap` installs Hammerspoon (the `hammerspoon` cask in `mise.macos.toml`).

## `init.lua`: input source follows USB devices

Switches the macOS input source based on which USB devices are attached:

| State                            | Input source                                                      |
| -------------------------------- | ----------------------------------------------------------------- |
| Any device in `DEVICES` attached | U.S.                                                              |
| None attached                    | Wilson Dvorak, or standard Dvorak if Wilson Dvorak is not enabled |

The check runs at config load and about one second after a plug or unplug event for a listed device. If the USB state can't be read, the input source is left unchanged.

### Configuration

Edit the constants at the top of `init.lua`:

```lua
local DEVICES = {
  { name = "Keychron V6 8K", vendorID = 0x3434, productID = 0x0F60, serial = "6885A90000C0A6210687BD1300000000" },
}

local ATTACHED_SOURCE = "com.apple.keylayout.US"
-- Tried in order when no listed device is attached; the first one that is enabled in
-- System Settings > Keyboard > Input Sources is used.
local DETACHED_SOURCES = {
  "org.sil.ukelele.keyboardlayout.unsavedukeleledocument.wilsondvorak", -- Wilson Dvorak, installed by hand
  "com.apple.keylayout.Dvorak", -- standard Dvorak
}
```

- `vendorID` and `productID` filter the events from `hs.usb.watcher`, which doesn't report serial numbers.
- `serial` is matched against `ioreg` output, so two units of the same model are told apart.
- `name` is for humans only.

### Finding a device's IDs

`ioreg` prints the values in decimal; convert them to hex for `vendorID` and `productID`:

```sh
ioreg -p IOUSB -l -w 0 | grep -E '"(USB Product Name|idVendor|idProduct|kUSBSerialNumberString)"'
```

### Finding input source IDs

Source IDs can be listed from the Hammerspoon console:

```lua
hs.inspect(hs.keycodes.layouts(true))
```

Custom layouts such as Wilson Dvorak (`~/Library/Keyboard Layouts/`) are not installed by this repo: install the layout by hand and enable it under System Settings > Keyboard > Input Sources. Until it is enabled, the detached state uses standard Dvorak (`com.apple.keylayout.Dvorak`); if neither is enabled, the input source is left unchanged and the console logs `usb-layout: none of … is enabled`.

### Applying changes

Reload the config from the Hammerspoon menu bar icon, or run `hs.reload()` in the console. Problems are logged to the Hammerspoon console with a `usb-layout:` prefix.
