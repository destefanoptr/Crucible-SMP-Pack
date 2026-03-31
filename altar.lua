core.register_node("crucible_smp_pack:altar", {
    description = ("The Altar") .. core.colorize("#06f831", "\nDurability: Infinite\nDamage: 9"),
    _doc_items_longdesc = sword_longdesc,
    drawtype = "mesh",
    mesh = "altar.obj",
    tiles = {"altar.png"},
    wield_scale = {x=3.1, y=3.1, z=1.8},
    use_texture_alpha = "clip",
    inventory_image = "altarinv.png",
    _mcl_toollike_wield = true,
    tool_capabilities = {
        full_punch_interval = 0.65,
        max_drop_level = 1,
        groupcaps = {
            snappy = {times = {[1]=1.50, [2]=0.60, [3]=0.30}, uses = 100, maxlevel = 3},
            cracky = {times = {[1]=1.90, [2]=0.90, [3]=0.40}, uses = 100, maxlevel = 3},
        },
        damage_groups = {fleshy = 12},
    },
    groups = {sword = 1, pickaxe = 1, dig_immediate = 3},
    _mcl_hardness = 1,
    _mcl_blast_resistance = 5,
    paramtype = "light",
    paramtype2 = "facedir",
    selection_box = {
        type = "fixed", 
        fixed = {
            {-0.32, -0.5, -0.3, 0.95, 1.05, 0.3},    
        },
    },
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        return itemstack
    end,
    
    -- Functionality to handle right-click with the item
    on_secondary_use = function(itemstack, player, pointed_thing)
        local current_time = os.time()
        
        if player:get_player_control().sneak then
            -- Shift click: launch 6 blocks
            local cooldown = player:get_meta():get_float("altar_launch_cooldown") or 0
            if current_time < cooldown then
                local remaining_time = cooldown - current_time
                core.chat_send_player(player:get_player_name(), "You must wait " .. remaining_time .. " seconds before launching again.")
                return itemstack
            end
            
            local look_dir = player:get_look_dir()
            -- About 6 blocks jump forward
            player:add_velocity(vector.multiply(look_dir, 25))
            core.sound_play("mcl_weather_wind", {
                pos = player:get_pos(),
                gain = 1.0,
                max_hear_distance = 16,
            })
            
            player:get_meta():set_float("altar_launch_cooldown", current_time + 5)
            return itemstack
        end
        
        -- Normal right click: Freeze Projectile
        local cooldown = player:get_meta():get_float("altar_freeze_cooldown") or 0
        if current_time < cooldown then
            local remaining_time = cooldown - current_time
            core.chat_send_player(player:get_player_name(), "You must wait " .. remaining_time .. " seconds before using the Altar freeze again.")
            return itemstack
        end
        
        local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
        if rc then return rc end

        local pos = player:get_pos()
        local look_dir = player:get_look_dir()
        pos.y = pos.y + 1.5
        local proj_velocity = vector.multiply(look_dir, 15)

        local obj = core.add_entity(pos, "crucible_smp_pack:altar_projectile")
        if obj then
            obj:set_velocity(proj_velocity)
            local luaent = obj:get_luaentity()
            if luaent then
                luaent.shooter = player
            end
            core.sound_play("mobs_mc_ender_dragon_shoot", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 30,
            })
        end

        -- Cooldown 25s
        player:get_meta():set_float("altar_freeze_cooldown", current_time + 25)
        
        return itemstack
    end,
})
