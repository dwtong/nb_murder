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

local function add_cv_env_player(index)
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

local function add_paraphonic_player()
    local player = {
        last_voice = 1,
        release_fns = {},
        alloc_modes = { "rotate", "random" },
    }

    function player:add_params()
        params:add_group("nb_crow_ii_paraphonic", "crow ii para", 6)
        params:add_number("nb_crow_ii_address_paraphonic", "ii address", 1, 4, 1)
        params:add_option("nb_crow_ii_alloc_type_paraphonic", "alloc type", self.alloc_modes, 1)
        params:add_option("nb_crow_ii_trigger_type_paraphonic", "trigger type", TRIGGER_TYPES, 1)
        params:add_control("nb_crow_ii_pulse_time_paraphonic", "pulse time", SPECS.slope)
        params:add_control("nb_crow_ii_attack_time_paraphonic", "attack time", SPECS.slope)
        params:add_control("nb_crow_ii_release_time_paraphonic", "release time", SPECS.slope)
        params:set_action("nb_crow_ii_trigger_type_paraphonic", function(value)
            local trigger_type = TRIGGER_TYPES[value]
            if trigger_type == "pulse" then
                params:show("nb_crow_ii_pulse_time_paraphonic")
                params:hide("nb_crow_ii_attack_time_paraphonic")
                params:hide("nb_crow_ii_release_time_paraphonic")
            elseif trigger_type == "ar" then
                params:hide("nb_crow_ii_pulse_time_paraphonic")
                params:show("nb_crow_ii_attack_time_paraphonic")
                params:show("nb_crow_ii_release_time_paraphonic")
            else
                params:hide("nb_crow_ii_pulse_time_paraphonic")
                params:hide("nb_crow_ii_attack_time_paraphonic")
                params:hide("nb_crow_ii_release_time_paraphonic")
            end
            _menu.rebuild_params()
        end)
        params:hide("nb_crow_ii_paraphonic")
    end

    function player:note_on(note, velocity)
        local trigger_channel = 4
        local trigger_type = TRIGGER_TYPES[params:get("nb_crow_ii_trigger_type_paraphonic")]
        local crow_index = params:get("nb_crow_ii_address_paraphonic")
        local pulse_time = params:get("nb_crow_ii_pulse_time_paraphonic")
        local attack_time = params:get("nb_crow_ii_attack_time_paraphonic")
        local release_time = params:get("nb_crow_ii_release_time_paraphonic")
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
        local alloc_mode = self.alloc_modes[params:get("nb_crow_ii_alloc_type_paraphonic")]
        if alloc_mode == "rotate" then
            next_voice = self.last_voice % voice_count + 1
            self.last_voice = next_voice
        elseif alloc_mode == "random" then
            next_voice = math.random(voice_count) + 1
        end
        crow.ii.crow[crow_index].volts(next_voice, note_volts)
    end

    function player:note_off(note)
        local trigger_type = TRIGGER_TYPES[params:get("nb_crow_ii_trigger_type_paraphonic")]
        if trigger_type ~= "gate" then
            return
        end
        if self.release_fns[note] then
            self.release_fns[note]()
        end
    end

    function player:describe()
        return {
            name = "crow ii para",
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:active()
        params:show("nb_crow_ii_paraphonic")
        _menu.rebuild_params()
    end

    function player:inactive()
        params:hide("nb_crow_ii_paraphonic")
        _menu.rebuild_params()
    end

    note_players[player:describe().name] = player
end

mod.hook.register("script_pre_init", "nb crow ii pre init", function()
    for i = 1, 2 do
        add_cv_env_player(i)
    end
    add_paraphonic_player()
end)
