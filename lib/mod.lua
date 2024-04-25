local mod = require("core/mods")

if note_players == nil then
    note_players = {}
end

local function add_player(index)
    local player = {
        id = index,
        cv_out = index * 2 - 1,
        env_out = index * 2,
    }

    function player:add_params()
        params:add_group("nb_crow_ii_" .. self.id, self:name(), 1)
        params:add_number("nb_crow_ii_address" .. self.id, "ii address", 1, 4, 1)
        params:hide("nb_crow_ii_" .. self.id)
    end

    function player:note_on(note, velocity)
        print(
            string.format(
                "note on. cv out ch: %d, env_out ch: %d, note: %d, velocity: %d",
                self.cv_out,
                self.env_out,
                note,
                velocity
            )
        )
    end

    function player:note_off(note)
        print("note off. note: " .. note)
    end

    function player:describe()
        return {
            name = self:name(),
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
        return string.format("crow (ii) %d/%d", self.cv_out, self.env_out)
    end

    note_players[player:name()] = player
end

mod.hook.register("script_pre_init", "nb crow (ii) pre init", function()
    for i = 1, 2 do
        add_player(i)
    end
end)
