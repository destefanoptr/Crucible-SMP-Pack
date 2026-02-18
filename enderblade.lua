core.register_node("crucible_smp_pack:enderblade", {
    description = ("Enderblade") .. core.colorize("#06f831", "\nDurability: Infinite\nDamage: 9"),
    _doc_items_longdesc = sword_longdesc,
    drawtype = "mesh",
    mesh = "enderdragonblade.obj",
    tiles = {"endblade.png"},
    wield_scale = {x=3.2, y=3.2, z=1.5},
    use_texture_alpha = "clip",
    inventory_image = "endbladeinv.png",
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
    
    -- Functionality to handle right-click with the item
    on_secondary_use = function(itemstack, player, pointed_thing)
        -- Check if the player has a cooldown attribute
        local cooldown = player:get_meta():get_float("enderblade_fireball_cooldown") or 0
        
        -- Get the current time
        local current_time = os.time()
        
        -- Check if the cooldown period has passed
        if current_time < cooldown then
            local remaining_time = cooldown - current_time
            core.chat_send_player(player:get_player_name(), "You must wait " .. remaining_time .. " seconds before using the Enderblade again.")
            return itemstack
        end
        
        -- Call the MCL right-click handler
        local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
        if rc then return rc end  -- If the call returns a valid value, stop further execution

        -- Get the player's position and look direction for the fireball
        local pos = player:get_pos()
        local look_dir = player:get_look_dir()

        -- Set position slightly above player and calculate velocity
        pos.y = pos.y + 1.5
        local fireball_velocity = vector.multiply(look_dir, 10)

        -- Summon the Ender Dragon fireball
        local obj = core.add_entity(pos, "mobs_mc:dragon_fireball")
        if obj then
            obj:set_velocity(fireball_velocity)

            -- Play the Ender Dragon attack sound
            core.sound_play("mobs_mc_ender_dragon_shoot", {
                pos = pos,
                gain = 1.0,
                max_hear_distance = 60,
                pitch = 1.0,
            })
        end

        -- Set cooldown for 30 seconds
        player:get_meta():set_float("enderblade_fireball_cooldown", current_time + 30)
        
        return itemstack  -- Return the itemstack to keep the Enderblade
    end,
})
