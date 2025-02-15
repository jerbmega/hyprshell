local astal = require("astal")
local Widget = require("astal.gtk3.widget")
local Variable = astal.Variable
local GLib = astal.require("GLib")
local bind = astal.bind
local Mpris = astal.require("AstalMpris")
local Battery = astal.require("AstalBattery")
local Wp = astal.require("AstalWp")
local Network = astal.require("AstalNetwork")
local Tray = astal.require("AstalTray")
local Hyprland = astal.require("AstalHyprland")
local map = require("lib").map

local function SysTray()
	local tray = Tray.get_default()

	return Widget.Box({
		class_name = "SysTray",
		bind(tray, "items"):as(function(items)
			return map(items, function(item)
				return Widget.MenuButton({
					tooltip_markup = bind(item, "tooltip_markup"),
					use_popover = false,
					menu_model = bind(item, "menu-model"),
					action_group = bind(item, "action-group"):as(
						function(ag) return { "dbusmenu", ag } end
					),
					Widget.Icon({
						gicon = bind(item, "gicon"),
					}),
				})
			end)
		end),
	})
end

local function FocusedClient()
	local hypr = Hyprland.get_default()
	local focused = bind(hypr, "focused-client")

	return Widget.Box({
		class_name = "Focused",
		visible = focused,
		focused:as(
			function(client)
				return client
					and Widget.Label({
						label = bind(client, "title"):as(tostring),
					})
			end
		),
	})
end

local function AudioSlider()

	return Widget.Box({
		class_name = "AudioSlider",
		css = "min-width: 140px;",

		Widget.Slider({
			hexpand = true,
			on_dragged = function(self) speaker.volume = self.value end,
			value = bind(speaker, "volume"),
		}),
	})
end

local function BatteryLevel()
	local bat = Battery.get_default()

	return Widget.Box({
		class_name = "Battery",
		visible = bind(bat, "is-present"),
		Widget.Icon({
			icon = bind(bat, "battery-icon-name"),
		}),
		Widget.Label({
			label = bind(bat, "percentage"):as(
				function(p) return tostring(math.floor(p * 100)) .. " %" end
			),
		}),
	})
end

local function Media()
	local player = Mpris.Player.new("feishin")

	return Widget.Box({
		class_name = "Media",
		visible = bind(player, "available"),
		Widget.Box({
			class_name = "Cover",
			valign = "CENTER",
			css = bind(player, "cover-art"):as(
				function(cover)
					return "background-image: url('" .. (cover or "") .. "');"
				end
			),
		}),
		Widget.Label({
			label = bind(player, "metadata"):as(
				function()
					return (player.title or "")
						.. " - "
						.. (player.artist or "")
				end
			),
		}),
	})
end

local function Workspaces(mon)
	local hypr = Hyprland.get_default()
    local mon = mon

	return Widget.Box({
		class_name = "Workspaces",
		bind(hypr, "workspaces"):as(function(wss)
			table.sort(wss, function(a, b) return a.id < b.id end)

			return map(wss, function(ws)
				if not (ws.id >= -99 and ws.id <= -2) then -- filter out special workspaces & workspaces not on this monitor
                    return Widget.Button({
						class_name = bind(hypr, "focused-workspace"):as(
                            function(fw)
                                if(fw == ws and ws.monitor.model ~= mon.model) then
                                    return "focused_offmonitor"
                                elseif fw == ws then return "focused"
                                elseif ws.monitor.model ~= mon.model then return "offmonitor"
                                else return "" end
                            end
						),
						on_clicked = function() ws:focus() end,
						label = bind(ws, "id"):as(
							function(v)
								return type(v) == "number"
										and string.format("%.0f", v)
									or v
							end
						),
					})
				end
			end)
		end),
	})
end

local function Time(format)
	local time = Variable(""):poll(
		1000,
		function() return GLib.DateTime.new_now_local():format(format) end
	)

	return Widget.Label({
		class_name = "Time",
		on_destroy = function() time:drop() end,
		label = time(),
	})
end


local function ControlCenter()
	local network = Network.get_default()
	local wifi = bind(network, "wifi")
    local wired = bind(network, "wired")

    local speaker = Wp.get_default().audio.default_speaker
    
    return Widget.Button({
		class_name = "ControlCenter";
		Widget.Box({
			class_name = "Icons";
			wired:as(
				function(w)
					return Widget.Icon({
						class_name = "Ethernet",
						icon = bind(w, "icon-name"),
					})
				end
			),
			wifi:as(
				function(w)
					return Widget.Icon({
						visible = bind(wired, "get_device") == nil,
						class_name = "Wifi",
						icon = bind(w, "icon-name"),
					})
				end
			),
			Widget.Icon({
				icon = bind(speaker, "volume-icon"),
			}),
			Widget.Icon({
				icon = "system-shutdown-symbolic",
			}),
		})
	})
end


return function(gdkmonitor)
	local Anchor = astal.require("Astal").WindowAnchor
	return Widget.Window({
		class_name = "Bar",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.BOTTOM + Anchor.LEFT + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		Widget.CenterBox({
			Widget.Box({
				halign = "START",
				Workspaces(gdkmonitor),
				FocusedClient(),
			}),
			Widget.Box({
				Media(),
                Time("%b %d %I:%M %p"),
			}),
			Widget.Box({
				halign = "END",
				SysTray(),
                ControlCenter(),
				BatteryLevel(),		
			}),
		}),
	})
end
