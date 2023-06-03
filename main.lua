local menu_key = 'q'
local favorite_tools_reg = 'savegame.mod.favorites'
local grid_width = 3
local menu_padding = 25
local scroll_sensitivity = 50
local basegame_tool_ids = {
    'sledge',
    'spraycan',
    'extinguisher',
    'blowtorch',
    'shotgun',
    'plank',
    'pipebomb',
    'gun',
    'bomb',
    'wire',
    'rocket',
    'booster',
    'leafblower',
    'turbo',
    'explosive',
    'rifle',
    'steroid'
}

local player_mods = {
    'Extra Speed',
    'Firewalk',
    'Fly',
    'Godmode',
    'Infinite Ammo',
    'Instant Win',
    'Unlimited Mission Time'
}

local speed = 0.6

function init()
    if not (GetString("savegame.mod.keybind") == "") then
        menu_key = GetString("savegame.mod.keybind")
    end

    local menu_open = false
    local menu_opened_before = false
    local all_tools = {}
    local menu_instance = {}

    generate_all_player_mods()

    recent_menu_height = 100
    scroll_pos = 0
end

function tick(dt)

    -- scrolling
    if menu_open then

        local new_scroll_pos = scroll_pos + InputValue("mousewheel") * scroll_sensitivity
        local diff_height = recent_menu_height - UiHeight() + menu_padding * 2

        -- prevent scrolling up
        if new_scroll_pos > 0 then
            new_scroll_pos = 0
        end

        -- prevent scrolling if menu to small
        if diff_height < 0 then
            new_scroll_pos = 0

        -- prevent scrolling past the end
        elseif new_scroll_pos < -diff_height then
            new_scroll_pos = -diff_height
        end

        -- update scroll variable
        scroll_pos = new_scroll_pos
    end

    -- toggle menu
    if InputPressed(menu_key) then

        -- when the menu is opened for the first time
        if not menu_opened_before then
            generate_all_tools()
            load_favorite_tools()
            menu_opened_before = true
        end

        -- on menu open
        if not menu_open then
            generate_menu_instance()
            update_tool_data()
            scroll_pos = 0
        end

        -- on menu close
        if menu_open then
            save_favorite_tools()
        end

        -- toggle menu open
        menu_open = not menu_open
    end

    -- player mods
    for i, mod in ipairs(all_player_mods) do
        if(mod.name == "Godmode" and mod.enabled == true) then
            SetPlayerHealth(1)
        elseif(mod.name == "Firewalk" and mod.enabled == true) then
            SpawnFire(VecAdd(GetPlayerTransform().pos, Vec(0,0,0)))
            SpawnParticle("fire", VecAdd(GetPlayerTransform().pos, Vec(0,0,0)), Vec(0, 1, 0), 1, 1)
        elseif(mod.name == "Fly" and mod.enabled == true) then
		    if InputDown("space") then
                JumpBoost()
            end
        elseif(mod.name == "Unlimited Mission Time" and mod.enabled == true) then
            SetFloat("level.alarmtimer", 60)
        elseif(mod.name == "Infinite Ammo" and mod.enabled == true) then
            SetInt("game.tool."..GetString("game.player.tool")..".ammo", 99999)
        elseif(mod.name == "Instant Win" and mod.enabled == true) then
            SetInt("level.clearedprimary", GetInt("level.primary"))
            SetInt("level.clearedsecondary", GetInt("level.secondary"))
            SetString("level.state", "win")
        elseif(mod.name == "Extra Speed" and mod.enabled == true) then
			if(GetPlayerVehicle() == 0 and InputDown("space") == false) then
                local pt = GetPlayerTransform()
                local d = TransformToParentVec(pt, Vec(0, 0, 0))
                local pvel = GetPlayerVelocity()
                local wboost = false
                local sboost = false
                local aboost = false
                local dboost = false
                if InputDown("w") and wboost == false then
                    d = TransformToParentVec(pt, Vec(0, 0, -speed))
                    pvel = VecAdd(pvel, d)
                    SetPlayerVelocity(pvel)
                    wboost = true
                elseif InputReleased("w") then
                    wboost = false
                elseif InputDown("s") and sboost == false then
                    d = TransformToParentVec(pt, Vec(0, 0, speed))
                    pvel = VecAdd(pvel, d)
                    SetPlayerVelocity(pvel)
                    sboost = true
                elseif InputReleased("s") then
                    sboost = false
                elseif InputDown("a") and aboost == false then
                    d = TransformToParentVec(pt, Vec(-speed, 0, 0))
                    pvel = VecAdd(pvel, d)
                    SetPlayerVelocity(pvel)
                    aboost = true
                elseif InputReleased("a") then
                    aboost = false
                elseif InputDown("d") and dboost == false then
                    d = TransformToParentVec(pt, Vec(speed, 0, 0))
                    pvel = VecAdd(pvel, d)
                    SetPlayerVelocity(pvel)
                    dboost = true
                elseif InputReleased("d") then
                    dboost = false
                end
            end
        end
    end
end

function draw()
    if menu_open then

        -- allow clicking on menu
        UiMakeInteractive()

        -- blurred underlay
        UiPush()
            UiColor(0, 0, 0, 0.2)
            UiBlur(0.5)
            UiRect(UiWidth(), UiHeight())
        UiPop()
        
        -- safe margins
        local x0, y0, x1, y1 = UiSafeMargins()
        UiTranslate(x0, y0)
        UiWindow(x1-x0, y1-y0, true)

        -- scrolling
        UiTranslate(0, scroll_pos)

        draw_menu()
    end
end

function update_tool_data()
    for i, tool in ipairs(all_tools) do
        tool.ammo = tonumber(get_tool_key(tool.id, 'ammo'))
    end
end

function generate_all_tools()
    all_tools = {}

    -- get all tools
    tool_ids = ListKeys('game.tool')
    for i, tool_id in ipairs(tool_ids) do
        tool_data = get_tool_data(tool_id)
        table.insert(all_tools, tool_data)
    end

    -- sort by index
    function by_index(a, b)
        if a == nil then
            return true
        end
        if b == nil then
            return false
        end
        return a.index < b.index
    end
    table.sort(all_tools, by_index)
end

function generate_all_player_mods()
    all_player_mods = {}

    -- get all player mods
    for i, player_mod in ipairs(player_mods) do
        player_mod_data = get_mod_data(player_mod)
        table.insert(all_player_mods, player_mod_data)
    end
end

function generate_menu_instance()
    menu_instance = {
        favorite={},
        modded={},
        basegame={},
        player={}
    }
    local divider = 1
    for i, tool in ipairs(all_tools) do
        if tool.favorite then
            table.insert(menu_instance.favorite, divider, tool)
            divider = divider + 1
        elseif is_tool_basegame(tool.id) then
            table.insert(menu_instance.basegame, tool)
        else
            table.insert(menu_instance.modded, tool)
        end
    end
end

function draw_menu()

    local width = 700

    UiTranslate(menu_padding, menu_padding)

    -- all sections
    local dy
    local last_height = 0

    dy = draw_tool_section('Favorite Weapons', menu_instance.favorite, width)
    last_height = last_height + dy

    UiTranslate(0, dy)
    dy = draw_tool_section('Base Game Weapons', menu_instance.basegame, width)
    last_height = last_height + dy

    UiTranslate(0, dy)
    dy = draw_tool_section('Modded Weapons', menu_instance.modded, width)
    last_height = last_height + dy

    UiTranslate(0, dy)
    dy = draw_menu_section('Player Mods', all_player_mods, width)
    last_height = last_height + dy

    recent_menu_height = last_height
end

function draw_menu_section(label, mods, width)
    local margin = 10
    local button_width = (width - (margin * 2)) / grid_width
    local button_height = 60
    local label_height = 30
    local height = 
        button_height * math.ceil(#mods / grid_width) + 
        label_height +
        margin * 3

    UiPush()

        -- background
        UiColor(0,0,0, 0.2)
        UiRect(width, height)

        -- label
        UiPush()
            UiTranslate(margin, label_height / 2 + margin)
            UiColor(1,1,1)
            UiAlign('left middle')
            UiFont('bold.ttf', 32)
            UiText(label)

        UiPop()
        UiTranslate(0, label_height)
        
        -- buttons
        UiTranslate(margin, margin)    
        for i, mod in ipairs(mods) do
            UiPush()
                local dx = button_width * ((i - 1)% grid_width)
                local dy = button_height * math.floor((i - 1) / grid_width)
                UiTranslate(dx, dy)
                draw_menu_button(mod, button_width, button_height)
            UiPop()
        end

    UiPop()

    return height
end

function draw_tool_section(label, tools, width)

    -- hide the section if there are no tools in it
    if #tools == 0 then
        return 0
    end

    local margin = 10
    local button_width = (width - (margin * 2)) / grid_width
    local button_height = 60
    local label_height = 30
    local height = 
        button_height * math.ceil(#tools / grid_width) + 
        label_height +
        margin * 3

    UiPush()

        -- background
        UiColor(0,0,0, 0.2)
        UiRect(width, height)

        -- label
        UiPush()
            UiTranslate(margin, label_height / 2 + margin)
            UiColor(1,1,1)
            UiAlign('left middle')
            UiFont('bold.ttf', 32)
            UiText(label)
            
            -- hold/store all
            UiColor(1,1,1, 0.3)
            UiAlign('right middle')
            local w, h = UiGetTextSize(label)
            UiTranslate(w + margin * 2, 0)
            if UiImageButton('white_hold.png') then
                for i, tool in ipairs(tools) do
                    set_tool_enabled(tool, true)
                end
            end
            UiTranslate(20, 0)
            if UiImageButton('storage.png') then
                for i, tool in ipairs(tools) do
                    set_tool_enabled(tool, false)
                end
            end

        UiPop()
        UiTranslate(0, label_height)
        
        -- tool buttons
        UiTranslate(margin, margin)    
        for i, tool in ipairs(tools) do
            UiPush()
                local dx = button_width * ((i - 1)% grid_width)
                local dy = button_height * math.floor((i - 1) / grid_width)
                UiTranslate(dx, dy)
                draw_tool_button(tool, button_width, button_height)
            UiPop()
        end

    UiPop()

    return height
end

function set_tool_enabled(tool, state)
    SetBool(string.format('game.tool.%s.enabled', tool.id), state)
    tool.enabled = state
end

function set_mod_enabled(mod, state)
    mod.enabled = state
end

function draw_menu_button(mod, width, height)
    local margin = 7
    local small_margin = 5
    UiPush()
        UiTranslate(margin, margin)
        UiWindow(width - (margin * 2), height - (margin * 2), true)

        UiColor(0,0,0,0.3)
        UiRect(UiWidth(), UiHeight())

        -- state
        UiPush()
            UiFont("regular.ttf", 20)
            UiAlign("top right")
            UiTranslate(UiWidth() - small_margin, small_margin)
            if(mod.enabled == true) then
                UiColor(0,1,1)
                UiText("On")
            else
                UiColor(1,0,0)
                UiText("Off")
            end
        UiPop()

        -- select label
        UiPush()
            UiColor(1,1,1)
            UiFont("regular.ttf", 24)
            UiWordWrap(width - margin * 2)
            UiAlign("center middle")
            UiTranslate(UiWidth() / 2, UiHeight() / 2)
            if UiTextButton(mod.name) then
                -- menu_open = false
                if (mod.enabled == false) then
                    set_mod_enabled(mod, true)
                else
                    set_mod_enabled(mod, false)
                end
            end
        UiPop()
    UiPop()
end

function draw_tool_button(tool, width, height)
    local margin = 7
    local small_margin = 5
    UiPush()
        UiTranslate(margin, margin)
        UiWindow(width - (margin * 2), height - (margin * 2), true)

        UiColor(0,0,0,0.3)
        UiRect(UiWidth(), UiHeight())

        -- favorite button
        UiPush()
            UiColor(1,1,1)
            UiAlign("top right")
            UiTranslate(UiWidth() - small_margin, small_margin)
            if UiImageButton(tool.favorite and 'star-solid.png' or 'star-outline.png') then
                tool.favorite = not tool.favorite
                generate_menu_instance()
            end
        UiPop()
        
        -- holding button
        UiPush()
            UiColor(1,1,1)
            UiAlign("top right")
            UiTranslate(UiWidth() - small_margin - 20, small_margin + 1)
            if UiImageButton(tool.enabled and 'hold.png' or 'storage.png') then
                set_tool_enabled(tool, not tool.enabled)
            end
        UiPop()

        -- select label
        UiPush()
            UiColor(1,1,1)
            UiFont("regular.ttf", 24)
            UiWordWrap(width - margin * 2)
            UiAlign("center middle")
            UiTranslate(UiWidth() / 2, UiHeight() / 2)
            if UiTextButton(tool.name) then
                SetString("game.player.tool", tool.id)
                menu_open = false
                set_tool_enabled(tool, true)
            end
        UiPop()

        -- ammo label
        if tool.ammo ~= nil then
            UiPush()
                UiColor(1,1,1,0.7)
                UiFont("regular.ttf", 16)
                UiAlign("top left")
                UiTranslate(margin, margin)
                UiImageBox('bullets.png', 16, 16, 0, 0)
                UiTranslate(-3, 17)
                UiText(math.floor(tool.ammo))
            UiPop()
        end
    UiPop()
end

function get_tool_key(tool_id, k)
    local result = string.format('game.tool.%s.%s', tool_id, k)
    return GetString(result)
end

function get_tool_data(tool_id)
    local data = {
        id = tool_id,
        name = get_tool_key(tool_id, 'name'),
        index = tonumber(get_tool_key(tool_id, 'index')),
        ammo = nil,
        favorite = false,
        enabled = true,
    }
    return data
end

function get_mod_data(mod)
    local data = {
        name = mod,
        enabled = false
    }
    return data
end

function is_tool_basegame(tool_id)
    return table_contains(basegame_tool_ids, tool_id)
end

function print_keys(parent)
    local keys = ListKeys(parent)
    DebugPrint(table.concat(keys, ", "))
end

function print_value(key)
    DebugPrint(GetString(key))
end

function split(string, delimiter)
    -- https://gist.github.com/jaredallard/ddb152179831dd23b230
    local result = {}
    local from  = 1
    local delim_from, delim_to = string.find( string, delimiter, from  )
    while delim_from do
        table.insert( result, string.sub( string, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( string, delimiter, from  )
    end
    table.insert( result, string.sub( string, from  ) )
    return result
end

function table_contains(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function save_favorite_tools()

    -- gather all favorite ids
    local favorite_ids = {}
    for i, tool in ipairs(all_tools) do
        if tool.favorite then
            table.insert(favorite_ids, tool.id)
        end
    end

    -- save to perst.
    local fav_string = table.concat(favorite_ids, ",")
    SetString(favorite_tools_reg, fav_string)
end

function load_favorite_tools()

    -- load from perst.
    local fav_string = GetString(favorite_tools_reg)
    local tool_ids = split(fav_string, ',')

    -- update the favorite status of the tools
    for i, tool_id in ipairs(tool_ids) do
        local index = tonumber(get_tool_key(tool_id, 'index'))
        if tonumber(index) ~= nil then
            all_tools[index].favorite = true
        end
    end
end

function JumpBoost()
	local pt = GetPlayerTransform()
	local d = TransformToParentVec(pt, Vec(0, 5, -0.5))
	local vel = GetPlayerVelocity()
	vel[2] = 0
	vel = VecAdd(vel, d)
	SetPlayerVelocity(vel)
end