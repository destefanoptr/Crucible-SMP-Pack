local MP = minetest.get_modpath("crucible_smp_pack")

dofile(MP.."/enderblade.lua")
dofile(MP.."/solaredge.lua")
dofile(MP.."/blood_dance_katana.lua")
dofile(MP.."/dark_retriver.lua")
dofile(MP.."/ruin.lua")
dofile(MP.."/altar.lua")

-- Inventory Effects Step
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 1 then return end
    timer = 0
    for _, player in ipairs(minetest.get_connected_players()) do
        local inv = player:get_inventory()
        if inv then
            local main = inv:get_list("main")
            local effects = {
                strength = 0,
                speed = 0,
                resistance = 0,
                fire_resistance = 0,
            }
            if main then
                for _, stack in ipairs(main) do
                    local name = stack:get_name()
                    if name == "crucible_smp_pack:enderblade" then
                        effects.strength = math.max(effects.strength, 1)
                        effects.speed = math.max(effects.speed, 2)
                        effects.resistance = math.max(effects.resistance, 1)
                    elseif name == "crucible_smp_pack:altar" then
                        effects.fire_resistance = math.max(effects.fire_resistance, 1)
                        effects.strength = math.max(effects.strength, 1)
                    elseif name == "crucible_smp_pack:blood_dance_katana" then
                        effects.speed = math.max(effects.speed, 3)
                        effects.strength = math.max(effects.strength, 1)
                    elseif name == "crucible_smp_pack:solaredge" then
                        effects.strength = math.max(effects.strength, 1)
                        effects.speed = math.max(effects.speed, 2)
                        effects.fire_resistance = math.max(effects.fire_resistance, 1)
                    elseif name == "crucible_smp_pack:dark_retriver" then 
                        effects.strength = math.max(effects.strength, 1)
                    elseif name == "crucible_smp_pack:ruin" then
                        effects.strength = math.max(effects.strength, 1)
                        effects.fire_resistance = math.max(effects.fire_resistance, 1)
                    end
                end
                
                if mcl_potions then
                    if effects.strength > 0 then mcl_potions.give_effect_by_level("strength", player, effects.strength, 2, true) end
                    if effects.speed > 0 then mcl_potions.give_effect_by_level("swiftness", player, effects.speed, 2, true) end
                    if effects.resistance > 0 then mcl_potions.give_effect_by_level("resistance", player, effects.resistance, 2, true) end
                    if effects.fire_resistance > 0 then mcl_potions.give_effect_by_level("fire_resistance", player, effects.fire_resistance, 2, true) end
                end
            end
        end
    end
end)

-- Blood Dance Backstab & Ruin Passive
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    if not hitter or not hitter:is_player() then return false end
    local wielded = hitter:get_wielded_item():get_name()
    
    if wielded == "crucible_smp_pack:blood_dance_katana" then
        local target_dir = player:get_look_dir()
        local hitter_dir = hitter:get_look_dir()
        local dot = (target_dir.x * hitter_dir.x) + (target_dir.y * hitter_dir.y) + (target_dir.z * hitter_dir.z)
        if dot > 0.5 then
            local extra_dmg = damage * 0.16
            
            if mcl_util and mcl_util.deal_damage then
                mcl_util.deal_damage(player, math.ceil(extra_dmg), {type = "player", source = hitter, direct = hitter})
            else
                player:set_hp(player:get_hp() - math.ceil(extra_dmg))
            end
            
            minetest.sound_play("mobs_mc_irongolem_hit", {
                pos = player:get_pos(),
                gain = 1.0,
                max_hear_distance = 16,
            })
            minetest.chat_send_player(hitter:get_player_name(), minetest.colorize("#ff0000", "Backstab!"))
        end
    elseif wielded == "crucible_smp_pack:ruin" then
        local target_pos = player:get_pos()
        local hitter_pos = hitter:get_pos()
        local pull_dir = vector.direction(target_pos, hitter_pos)
        player:add_velocity(vector.multiply(pull_dir, 15))
    end
end)

-- Projectiles Registrations

minetest.register_entity("crucible_smp_pack:altar_projectile", {
    initial_properties = {
        hp_max = 1,
        physical = false,
        collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
        visual = "sprite",
        textures = {"snowball.png"},
        visual_size = {x = 1, y = 1},
    },
    timer = 0,
    shooter = nil,
    
    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > 5 then
            self.object:remove()
            return
        end
        local pos = self.object:get_pos()
        for _, obj in pairs(minetest.get_objects_inside_radius(pos, 4.0)) do
            if obj:is_player() and self.shooter and self.shooter:is_player() and obj:get_player_name() ~= self.shooter:get_player_name() then
                -- Freeze completely using physics overrides instead of potion effects
                obj:set_physics_override({speed = 0, jump = 0, sneak = false})
                
                -- Forcefully lock them in place with recurrent teleports to ensure total stasis
                local freeze_pos = obj:get_pos()
                
                local lock_timer = 0
                -- We spawn a tiny global loop or just repeated afters to lock
                local function lock_pos()
                    if lock_timer < 10 then
                        if obj and obj:is_player() then
                            obj:set_pos(freeze_pos)
                            obj:set_physics_override({speed = 0, jump = 0, sneak = false})
                        end
                        lock_timer = lock_timer + 0.5
                        minetest.after(0.5, lock_pos)
                    else
                        if obj and obj:is_player() then
                            obj:set_physics_override({speed = 1, jump = 1, sneak = true})
                        end
                    end
                end
                
                lock_pos()
                
                self.object:remove()
                return
            end
        end
    end,
})

minetest.register_entity("crucible_smp_pack:solar_fireball", {
    initial_properties = {
        hp_max = 1,
        physical = false,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "sprite",
        textures = {"fire_basic_flame.png"},
        visual_size = {x = 2, y = 2},
    },
    timer = 0,
    shooter = nil,
    
    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > 10 then
            self.object:remove()
            return
        end
        
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos)
        if node.name ~= "air" and node.name ~= "ignore" and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].walkable then
            if mcl_explosions then
                mcl_explosions.explode(pos, 5, {drop_chance=0, fire=true})
                self.object:remove()
                return
            end
        end
        
        for _, obj in pairs(minetest.get_objects_inside_radius(pos, 2)) do
            local is_shooter = false
            if obj:is_player() and self.shooter and self.shooter:is_player() then
                is_shooter = (obj:get_player_name() == self.shooter:get_player_name())
            end
            if (obj:is_player() and not is_shooter) or (not obj:is_player() and obj:get_luaentity() and obj:get_luaentity().is_mob) then
                if mcl_explosions then
                    mcl_explosions.explode(pos, 5, {drop_chance=0, fire=true})
                    self.object:remove()
                    return
                end
            end
        end
    end,
})

minetest.register_entity("crucible_smp_pack:dark_hook", {
    initial_properties = {
        hp_max = 1,
        physical = false,
        collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
        visual = "cube",
        textures = {"default_obsidian.png", "default_obsidian.png", "default_obsidian.png", "default_obsidian.png", "default_obsidian.png", "default_obsidian.png"},
        visual_size = {x = 0.2, y = 0.2, z = 0.2},
    },
    timer = 0,
    shooter = nil,
    
    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > 5 or not self.shooter or not self.shooter:is_player() then
            self.object:remove()
            return
        end
        
        local pos = self.object:get_pos()
        for _, obj in pairs(minetest.get_objects_inside_radius(pos, 3.0)) do
            local is_shooter = false
            if obj:is_player() and self.shooter and self.shooter:is_player() then
                is_shooter = (obj:get_player_name() == self.shooter:get_player_name())
            end
            
            if not is_shooter and (obj:is_player() or (not obj:is_player() and obj:get_luaentity() and obj:get_luaentity().is_mob)) then
                local shooter_pos = self.shooter:get_pos()
                local look_dir = self.shooter:get_look_dir()
                local target_dest = vector.add(shooter_pos, vector.multiply(look_dir, 1.5))
                
                if obj:is_player() then
                    obj:set_hp(math.max(0, obj:get_hp() - 9))
                end
                
                obj:set_pos(target_dest)
                
                self.object:remove()
                return
            end
        end
    end,
})
