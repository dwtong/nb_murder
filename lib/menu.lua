local m = {}

local mod = require("core/mods")

local device_max = 4
local data_dir = _path.data .. mod.this_name
local data_file = data_dir .. "/mod.state"

-- default state
local state = {
    device_count = 1,
}

m.key = function(n, z)
    if n == 2 and z == 1 then
        mod.menu.exit()
    end
end

m.enc = function(n, d)
    if n == 3 then
        local device_count = util.clamp(state.device_count + d, 1, device_max)
        state.device_count = device_count
    end
    mod.menu.redraw()
end

m.redraw = function()
    screen.clear()
    screen.font_face(1)
    screen.font_size(8)
    screen.level(15)
    screen.move(0, 10)
    screen.text("device count")
    screen.move(120, 10)
    screen.text(state.device_count)
    screen.update()
end

m.init = function()
    if util.file_exists(data_file) then
        state = tab.load(data_file)
    else
        util.make_dir(data_dir)
    end
end

m.deinit = function()
    tab.save(state, data_file)
end

return m
