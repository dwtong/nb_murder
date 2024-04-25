local mod = require("core/mods")
local menu = require("nb_murder/lib/menu")

local TRIGGER_TYPES = { "gate", "pulse", "ar" }
local SPECS = {
    slope = controlspec.def({
        min = 0.0001,
        max = 10,
        warp = "exp",
        step = 0,
        default = 0.1,
        units = "s",
    }),
}

local device_count
local data_file = _path.data .. mod.this_name .. "/mod.state"

if note_players == nil then
    note_players = {}
end

local function note_to_volts(note)
    return note * (1 / 12)
end

local function param_name(player, param)
    return string.format("nb_crow_ii_%d_%s_%s", player.device, player.id, param)
end

local function player_name(player)
    local player_type
    if player.id == "para" then
        player_type = "para"
    else
        player_type = string.format("%d/%d", player.cv_out, player.env_out)
    end
    if device_count == 1 then
        return "crow ii " .. player_type
    else
        return string.format("crow ii (%d) %s", player.device, player_type)
    end
end

local function on_trigger_type(player, trigger_type_index)
    local trigger_type = TRIGGER_TYPES[trigger_type_index]
    if trigger_type == "pulse" then
        params:show(param_name(player, "pulse_time"))
        params:hide(param_name(player, "attack_time"))
        params:hide(param_name(player, "release_time"))
    elseif trigger_type == "ar" then
        params:hide(param_name(player, "pulse_time"))
        params:show(param_name(player, "attack_time"))
        params:show(param_name(player, "release_time"))
    else
        params:hide(param_name(player, "pulse_time"))
        params:hide(param_name(player, "attack_time"))
        params:hide(param_name(player, "release_time"))
    end
    _menu.rebuild_params()
end

local function add_cv_env_player(device, index)
    local player = {
        id = tostring(index),
        device = device,
        cv_out = index * 2 - 1,
        env_out = index * 2,
    }

    function player:add_params()
        params:add_group(param_name(player, "group"), player_name(self), 5)
        params:add_number(param_name(player, "ii_address"), "ii address", 1, 4, self.device)
        params:add_option(param_name(player, "trigger_type"), "trigger type", TRIGGER_TYPES, 1)
        params:add_control(param_name(player, "pulse_time"), "pulse time", SPECS.slope)
        params:add_control(param_name(player, "attack_time"), "attack time", SPECS.slope)
        params:add_control(param_name(player, "release_time"), "release time", SPECS.slope)
        params:set_action(param_name(player, "trigger_type"), function(value)
            on_trigger_type(self, value)
        end)
        params:hide(param_name(player, "group"))
    end

    function player:note_on(note, velocity)
        local crow_index = params:get(param_name(player, "ii_address"))
        local note_volts = note_to_volts(note)
        local trigger_type = TRIGGER_TYPES[params:get(param_name(player, "trigger_type"))]
        local pulse_time = params:get(param_name(player, "pulse_time"))
        local attack_time = params:get(param_name(player, "attack_time"))
        local release_time = params:get(param_name(player, "row_ii_release_time"))
        if trigger_type == "gate" then
            crow.ii.crow[crow_index].volts(self.env_out, 10)
        elseif trigger_type == "pulse" then
            crow.ii.crow[crow_index].pulse(self.env_out, pulse_time, 10, 1)
        elseif trigger_type == "ar" then
            crow.ii.crow[crow_index].ar(self.env_out, attack_time, release_time, velocity * 10)
        end
        crow.ii.crow[crow_index].volts(self.cv_out, note_volts)
    end

    function player:note_off()
        local trigger_type = TRIGGER_TYPES[params:get(param_name(player, "trigger_type"))]
        if trigger_type ~= "gate" then
            return
        end
        local crow_index = params:get(param_name(player, "ii_address"))
        crow.ii.crow[crow_index].volts(self.env_out, 0)
    end

    function player:describe()
        return {
            name = player_name(player),
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:active()
        params:show(param_name(player, "group"))
        _menu.rebuild_params()
    end

    function player:inactive()
        params:hide(param_name(player, "group"))
        _menu.rebuild_params()
    end

    note_players[player_name(player)] = player
end

local function add_paraphonic_player(device)
    local player = {
        id = "para",
        device = device,
        last_voice = 1,
        release_fns = {},
        alloc_modes = { "rotate", "random" },
    }

    function player:add_params()
        params:add_group(param_name(player, "group"), player_name(self), 6)
        params:add_number(param_name(player, "ii_address"), "ii address", 1, 4, self.device)
        params:add_option(param_name(player, "alloc_type"), "alloc type", self.alloc_modes, 1)
        params:add_option(param_name(player, "trigger_type"), "trigger type", TRIGGER_TYPES, 1)
        params:add_control(param_name(player, "pulse_time"), "pulse time", SPECS.slope)
        params:add_control(param_name(player, "attack_time"), "attack time", SPECS.slope)
        params:add_control(param_name(player, "release_time"), "release time", SPECS.slope)
        params:set_action(param_name(player, "trigger_type"), function(value)
            on_trigger_type(self, value)
        end)
        params:hide(param_name(player, "group"))
    end

    function player:note_on(note, velocity)
        local trigger_channel = 4
        local trigger_type = TRIGGER_TYPES[params:get(param_name(player, "trigger_type"))]
        local crow_index = params:get(param_name(player, "ii_address"))
        local pulse_time = params:get(param_name(player, "pulse_time"))
        local attack_time = params:get(param_name(player, "attack_time"))
        local release_time = params:get(param_name(player, "release_time"))
        self.release_fns[note] = function()
            crow.ii.crow[crow_index].volts(trigger_channel, 0)
        end
        if trigger_type == "gate" then
            crow.ii.crow[crow_index].volts(trigger_channel, 10)
        elseif trigger_type == "pulse" then
            crow.ii.crow[crow_index].pulse(trigger_channel, pulse_time, 10, 1)
        elseif trigger_type == "ar" then
            crow.ii.crow[crow_index].ar(trigger_channel, attack_time, release_time, velocity * 10)
        end

        local next_voice
        local voice_count = 3
        local note_volts = note_to_volts(note)
        local alloc_mode = self.alloc_modes[params:get(param_name(player, "alloc_type"))]
        if alloc_mode == "rotate" then
            next_voice = self.last_voice % voice_count + 1
            self.last_voice = next_voice
        elseif alloc_mode == "random" then
            next_voice = math.random(voice_count) + 1
        end
        crow.ii.crow[crow_index].volts(next_voice, note_volts)
    end

    function player:note_off(note)
        local trigger_type = TRIGGER_TYPES[params:get(param_name(player, "trigger_type"))]
        if trigger_type ~= "gate" then
            return
        end
        if self.release_fns[note] then
            self.release_fns[note]()
        end
    end

    function player:describe()
        return {
            name = player_name(player),
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:active()
        params:show(param_name(player, "group"))
        _menu.rebuild_params()
    end

    function player:inactive()
        params:hide(param_name(player, "group"))
        _menu.rebuild_params()
    end

    note_players[player_name(player)] = player
end

mod.hook.register("script_pre_init", "nb crow ii pre init", function()
    if util.file_exists(data_file) then
        device_count = tab.load(data_file).device_count
    else
        device_count = 1
    end

    for device = 1, device_count do
        for i = 1, 2 do
            add_cv_env_player(device, i)
        end
        add_paraphonic_player(device)
    end
end)

mod.menu.register(mod.this_name, menu)
