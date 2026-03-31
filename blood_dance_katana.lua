core.register_node("crucible_smp_pack:blood_dance_katana", {
    description = ("Blood Dance Katana") .. core.colorize("#06f831", "\nDurability: Infinite\nDamage: 9"),
    _doc_items_longdesc = sword_longdesc,
    drawtype = "mesh",
    mesh = "blood_dance_katana.obj",
    tiles = {"blood_dance_katana.png"},
    wield_scale = {x=8, y=8, z=4},
    use_texture_alpha = "clip",
    inventory_image = "blood_dance_katanainv.png",
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
        
        -- Normal right click: Teleport to nearest player
        local cooldown = player:get_meta():get_float("blood_dance_tp_cooldown") or 0
        if current_time < cooldown then
            local remaining_time = cooldown - current_time
            core.chat_send_player(player:get_player_name(), "You must wait " .. remaining_time .. " seconds before using the Blood Dance teleport again.")
            return itemstack
        end
        
        local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
        if rc then return rc end

        local pos = player:get_pos()
        local nearest_player = nil
        local nearest_dist = 11 -- max dist 10
        
        for _, obj in pairs(minetest.get_objects_inside_radius(pos, 10)) do
            if obj:is_player() and obj ~= player then
                local dist = vector.distance(pos, obj:get_pos())
                if dist < nearest_dist then
                    nearest_dist = dist
                    nearest_player = obj
                end
            end
        end

        if nearest_player then
            local target_pos = nearest_player:get_pos()
            -- teleport slightly behind or near them? the prompt said "teleport you To the nearest person"
            player:set_pos(target_pos)
            
            if mcl_potions then
                mcl_potions.give_effect_by_level("slowness", nearest_player, 1, 14, false)
                mcl_potions.give_effect_by_level("poison", nearest_player, 1, 60, false)
            end
            
            core.sound_play("mobs_mc_enderman_teleport", {
                pos = target_pos,
                gain = 1.0,
                max_hear_distance = 16,
            })
            
            player:get_meta():set_float("blood_dance_tp_cooldown", current_time + 30)
        else
            core.chat_send_player(player:get_player_name(), "No players found within 10 blocks!")
        end
        
        return itemstack
    end,
})
