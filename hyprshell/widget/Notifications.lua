local astal = require("astal")
local Widget = require("astal.gtk3.widget")
local Hyprland = astal.require("AstalHyprland")
local notifd = astal.require("AstalNotifd").get_default()

local bind = astal.bind
local astalify = astal.astalify
local timeout = astal.timeout

local file_exists = require("lib").file_exists
local async_sleep = require("lib").async_sleep

local notifications = {}

local active_notification = nil

local function Image(n)
	return (n.image and file_exists(n.image)) and
        Widget.Box(
            {
                valign = "START",
                class_name = "image",
                css = string.format("background-image: url('%s')", n.image)
            }
        )
end

local function Header(n)
    icon = nil

    if n.app_icon ~= "" then
        icon = n.app_icon
    elseif n.desktop_entry and n.desktop_entry ~= "" then
        -- this might backfire, so we'll have to check if this always works
        icon = n.desktop_entry:lower() .. "-symbolic"
    end

    return Widget.Box(
        {
            class_name = "header",
            icon and
                Widget.Icon(
                    {
                        class_name = "icon",
                        icon = icon
                    }
                ),
            Widget.Label(
                {
                    class_name = "name",
                    label = (n.app_name ~= "") and n.app_name or "Unknown",
                    hexpand = true,
                    halign = "START",
                }
            ),
            Widget.Button({
                class_name = "close circular",
                valign = "END",
                Widget.Icon({
                    icon = "window-close-symbolic",
                }),
                on_clicked = function(self) self:get_parent_window():destroy() end
            })
        }
    )
end

local function Actions(n)
    actions = {}

    for _, action in pairs(n.actions) do
        if action.label ~= "" then
			table.insert(
				actions,
				Widget.Button(
					{
						hexpand = true,
						on_clicked = function()
							return n:invoke(action.id)
						end,
						Widget.Label(
							{
								label = action.label,
								halign = "CENTER",
								hexpand = true
							}
						)
					}
				)
			)
		end
    end
    return Widget.Box(actions)
end

local function NotificationPopup(n)
    local Anchor = astal.require("Astal").WindowAnchor
    local Layer = astal.require("Astal").Layer
    
    if active_notification then
        active_notification:destroy()
    end

    active_notification = Widget.Window(
        {
            class_name = "notification_popup",
            anchor = Anchor.TOP,
			margin_top = 10,
            layer = Layer.OVERLAY,
            Widget.Box(
                {
                    class_name = "container",
                    vertical = true,
					setup = function(self)
						timeout(5000, function()
							self:destroy()
						end)
					end,
                    Header(n),
                    Widget.Box(
                        {
                            class_name = "content",
                            Image(n),
                            Widget.Box(
                                {
                                    vertical = true,
                                    Widget.Label(
                                        {
                                            class_name = "summary",
                                            halign = "START",
                                            xalign = 0,
                                            ellipsize = "END",
                                            label = n.summary
                                        }
                                    ),
                                    Widget.Label(
                                        {
                                            class_name = "body",
                                            wrap = true,
                                            use_markup = true,
                                            halign = "START",
											valign = "START",
                                            xalign = 0,
                                            label = n.body,
											vexpand = true
                                        }
                                    ),
                                    -- Actions(n) TODO: make these not suck
                                }
                            )
                        }
                    )
                }
            )
        }
    )

    return active_notification
end

notifd.on_notified = function(_, id)
    local n = notifd:get_notification(id)
    NotificationPopup(n)
end
