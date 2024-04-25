local mod = require("core/mods")

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

if note_players == nil then
    note_players = {}
end

local function note_to_volts(note)
    return note * (1 / 12)
end

local function add_player(index)
    local player = {
        id = index,
        cv_out = index * 2 - 1,
        env_out = index * 2,
    }

    function player:add_params()
        params:add_group("nb_crow_ii_" .. self.id, self:name(), 5)
        params:add_number("nb_crow_ii_address_" .. self.id, "ii address", 1, 4, 1)
        params:add_option("nb_crow_ii_trigger_type_" .. self.id, "trigger type", TRIGGER_TYPES, 1)
        params:add_control("nb_crow_ii_pulse_time_" .. self.id, "pulse time", SPECS.slope)
        params:add_control("nb_crow_ii_attack_time_" .. self.id, "attack time", SPECS.slope)
        params:add_control("nb_crow_ii_release_time_" .. self.id, "release time", SPECS.slope)
        params:set_action("nb_crow_ii_trigger_type_" .. self.id, function(value)
            local trigger_type = TRIGGER_TYPES[value]
            if trigger_type == "pulse" then
                params:show("nb_crow_ii_pulse_time_" .. self.id)
                params:hide("nb_crow_ii_attack_time_" .. self.id)
                params:hide("nb_crow_ii_release_time_" .. self.id)
            elseif trigger_type == "ar" then
                params:hide("nb_crow_ii_pulse_time_" .. self.id)
                params:show("nb_crow_ii_attack_time_" .. self.id)
                params:show("nb_crow_ii_release_time_" .. self.id)
            else
                params:hide("nb_crow_ii_pulse_time_" .. self.id)
                params:hide("nb_crow_ii_attack_time_" .. self.id)
                params:hide("nb_crow_ii_release_time_" .. self.id)
            end
            _menu.rebuild_params()
        end)
        params:hide("nb_crow_ii_" .. self.id)
    end

    function player:note_on(note, velocity)
        local crow_index = params:get("nb_crow_ii_address_" .. self.id)
        local note_volts = note_to_volts(note)
        local trigger_type = TRIGGER_TYPES[params:get("nb_crow_ii_trigger_type_" .. self.id)]
        local pulse_time = params:get("nb_crow_ii_pulse_time_" .. self.id)
        local attack_time = params:get("nb_crow_ii_attack_time_" .. self.id)
        local release_time = params:get("nb_crow_ii_release_time_" .. self.id)
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
        local trigger_type = TRIGGER_TYPES[params:get("nb_crow_ii_trigger_type_" .. self.id)]
        if trigger_type ~= "gate" then
            return
        end
        local crow_ii = crow.ii.crow[params:get("nb_crow_ii_address_" .. self.id)]
        crow_ii.volts(self.env_out, 0)
    end

    function player:describe()
        return {
            name = name,
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:active()
        params:show("nb_crow_ii_" .. self.id)
        _menu.rebuild_params()
    end

    function player:inactive()
        params:hide("nb_crow_ii_" .. self.id)
        _menu.rebuild_params()
    end

    function player:name()
        return string.format("crow ii %d/%d", self.cv_out, self.env_out)
    end

    note_players[player:name()] = player
end

mod.hook.register("script_pre_init", "nb crow ii pre init", function()
    for i = 1, 2 do
        add_player(i)
    end
end)
