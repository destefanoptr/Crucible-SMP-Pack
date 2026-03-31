core.register_node("crucible_smp_pack:ruin", {
    description = ("Ruin") .. core.colorize("#06f831", "\nDurability: Infinite\nDamage: 10"),
    _doc_items_longdesc = sword_longdesc,
    drawtype = "mesh",
    mesh = "ruin.obj",
    tiles = {"ruin.png"},
    wield_scale = {x=2, y=2, z=1},
    use_texture_alpha = "clip",
    inventory_image = "ruininv.png",
    _mcl_toollike_wield = true,
    tool_capabilities = {
        full_punch_interval = 1.25,
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
        
        -- Right click: Heal
        local cooldown = player:get_meta():get_float("ruin_heal_cooldown") or 0
        if current_time < cooldown then
            local remaining_time = cooldown - current_time
            core.chat_send_player(player:get_player_name(), "You must wait " .. remaining_time .. " seconds before healing again.")
            return itemstack
        end
        
        local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
        if rc then return rc end

        -- instant_health level 1 = 4 HP (2 hearts)
        player:set_hp(math.min(player:get_properties().hp_max, player:get_hp() + 4))
        
        core.sound_play("mcl_potions_drink", {
            pos = player:get_pos(),
            gain = 1.0,
            max_hear_distance = 16,
        })

        player:get_meta():set_float("ruin_heal_cooldown", current_time + 20)
        
        return itemstack
    end,
})
