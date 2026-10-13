-- Switch the input source based on whether any of the listed USB devices is attached:
-- any attached -> ATTACHED_SOURCE, none attached -> the first enabled DETACHED_SOURCES entry.
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

local function anyDeviceAttached()
  -- hs.usb doesn't expose serial numbers, so ask the IORegistry.
  local output, ok = hs.execute("/usr/sbin/ioreg -p IOUSB -l -w 0")
  if not ok then
    return nil
  end
  for _, device in ipairs(DEVICES) do
    if output:find(device.serial, 1, true) then
      return true
    end
  end
  return false
end

local function isListedDevice(event)
  for _, device in ipairs(DEVICES) do
    if event.vendorID == device.vendorID and event.productID == device.productID then
      return true
    end
  end
  return false
end

local function firstAvailable(sources)
  local available = {}
  for _, id in ipairs(hs.keycodes.layouts(true)) do
    available[id] = true
  end
  for _, id in ipairs(sources) do
    if available[id] then
      return id
    end
  end
  return nil
end

local function applyInputSource()
  local attached = anyDeviceAttached()
  if attached == nil then
    hs.printf("usb-layout: could not read USB state; leaving input source unchanged")
    return
  end

  local source = attached and ATTACHED_SOURCE or firstAvailable(DETACHED_SOURCES)
  if not source then
    hs.printf("usb-layout: none of %s is enabled; leaving input source unchanged", table.concat(DETACHED_SOURCES, ", "))
    return
  end
  if hs.keycodes.currentSourceID() ~= source and not hs.keycodes.currentSourceID(source) then
    hs.printf("usb-layout: could not switch input source to %s", source)
  end
end

usbWatcher = hs.usb.watcher.new(function(event)
  if isListedDevice(event) then
    -- Give the IORegistry a moment to settle after the event.
    hs.timer.doAfter(1, applyInputSource)
  end
end)
usbWatcher:start()

applyInputSource()
