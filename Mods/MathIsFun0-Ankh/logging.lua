local lovely = require("lovely")
local nativefs = require("nativefs")

DejaVu = {sort_memory = {}}
DejaVu.Actions = {
    REARRANGE_JOKERS = "A",
    REARRANGE_CONSUMABLES = "B",
    REARRANGE_HAND = "C",
    START_RUN = "D",
    CONTINUE_RUN = "E",
    SELECT_BLIND = "F",
    SKIP_BLIND = "G",
    PLAY_HAND = "H",
    DISCARD_HAND = "I",
    END_SHOP = "J",
    REROLL_SHOP = "K",
    SKIP_BOOSTER_PACK = "L",
    SELECT_BOOSTER_CARD = "M",
    BUY_CARD = "N",
    BUY_VOUCHER = "O",
    BUY_BOOSTER = "P",
    USE_THIS_CARD = "Q",
    USE_CONSUMABLE = "R",
    SELL_JOKER = "S",
    SELL_CONSUMABLE = "T",
    SHOW_SEED = "U",
    LOG = "V",
    WIN_RUN = "W",
    LOSE_RUN = "X",
    SORT_RANK = "Y",
    SORT_SUIT = "Z"
}
function DejaVu.log(event, extra)
    if not DejaVu.replay then
        if not DejaVu.run_log then 
            DejaVu.run_log = ""
            if G.GAME.log then DejaVu.run_log = DejaVu.decode(G.GAME.log, true) end
        end
        DejaVu.run_log = DejaVu.run_log..(DejaVu.run_log == "" and "" or "\n")..Speedrun.TIMERS.CURRENT_RUN.." - "..DejaVu.Actions[event]..(extra and "|"..extra or "")
        G.GAME.log = DejaVu.encode()
        if event == "START_RUN" then
            if not G.GAME.seeded then
                DejaVu.log("LOG",string.format("%.20f",G.CONTROLLER.cursor_hover.T.x).."|"..string.format("%.20f",G.CONTROLLER.cursor_hover.T.y).."|"..string.format("%.20f",G.CONTROLLER.cursor_hover.time))
                local exePath = love.filesystem.getSourceBaseDirectory().."\\Balatro.exe"
                local hash = nil
                if love.system.getOS() == "Windows" then
                local handle = io.popen("certutil -hashfile \""..exePath.."\" SHA256")
                local currentLine = 1
                for line in handle:lines() do
                    if currentLine == 2 then
                        hash = line
                        break
                    end
                    currentLine = currentLine + 1
                end
                handle:close()
                elseif love.system.getOS() == "OS X" then
                local handle = io.popen("shasum -a 256 \""..exePath.."\"")
                local output = handle:read("*a")
                hash = output:match("(%x+)%s")
                handle:close()
                elseif love.system.getOS() == "Linux" then
                local handle = io.popen("sh256sum \""..exePath.."\"")
                local output = handle:read("*a")
                hash = output:match("(%x+)%s")
                handle:close()
                end
                local game_lua = nativefs.read(lovely.mod_dir.."/lovely/dump/game.lua")
                local game_lua = game_lua and game_lua:match("'(.-)'")
                local main_lua = nativefs.read(lovely.mod_dir.."/lovely/dump/main.lua")
                local main_lua = main_lua and main_lua:match("'(.-)'")
                DejaVu.log("LOG",hash)
                DejaVu.log("LOG",string.format("%.20f",Speedrun.pseudohash(nativefs.read(lovely.mod_dir.."/MathIsFun0-Ankh/Ankh.lua"))).."|"..string.format("%.20f",Speedrun.pseudohash(nativefs.read(lovely.mod_dir.."/MathIsFun0-Ankh/lovely.toml"))))
                DejaVu.log("LOG",game_lua.."|"..main_lua)
                DejaVu.log("LOG",string.format("%.20f",Speedrun.pseudohash(debug.getinfo(1, "S").source:sub(2))))
            end
        end
    end
end

local cui_win = create_UIBox_win
function create_UIBox_win()
    DejaVu.log("LOG","WIN_RUN")
    DejaVu.save_to_file()
    return cui_win()
end
local cui_lose = create_UIBox_game_over
function create_UIBox_game_over()
    DejaVu.log("LOG","LOSE_RUN")
    DejaVu.save_to_file()
    return cui_lose()
end

function DejaVu.check_rearrange(area,mem_id,event)
    if not DejaVu.sort_memory[mem_id] or #DejaVu.sort_memory[mem_id] ~= #area.cards then
        DejaVu.sort_memory[mem_id] = {}
        for i = 1, #area.cards do
            DejaVu.sort_memory[mem_id][i] = area.cards[i].sort_id
        end
    end
    local mem = DejaVu.sort_memory[mem_id]
    local all_found_match = true
    for i = 1, #area.cards do
        local found_match = false
        for j = 1, #mem do
            if mem[j] == area.cards[i].sort_id then found_match = true end
        end
        if not found_match then all_found_match = false break end
    end
    if not all_found_match then
        DejaVu.sort_memory[mem_id] = {}
        for i = 1, #area.cards do
            DejaVu.sort_memory[mem_id][i] = area.cards[i].sort_id
        end
    end
    local rearranged = false
    for i = 1, #area.cards do
        if area.cards[i].sort_id ~= mem[i] then rearranged = true break end
    end
    if rearranged then
        local rearrangement = ""
        for i = 1, #mem do
            local new_idx = 0
            for j = 1, #area.cards do
                if area.cards[j].sort_id == mem[i] then
                    new_idx = j break
                end
            end
            rearrangement = rearrangement..new_idx.."|"
        end
        if not DejaVu.sort_bypass then DejaVu.log(event,rearrangement) else DejaVu.sort_bypass = false end
        DejaVu.sort_memory[mem_id] = {}
        for i = 1, #area.cards do
            DejaVu.sort_memory[mem_id][i] = area.cards[i].sort_id
        end
    end
end

local upd = Game.update
function Game:update(dt)
    if G.GAME then
        if G.jokers then DejaVu.check_rearrange(G.jokers,"jokers","REARRANGE_JOKERS") end
        if G.consumeables then DejaVu.check_rearrange(G.consumeables,"consumeables","REARRANGE_CONSUMABLES") end
        if G.hand then DejaVu.check_rearrange(G.hand,"hand","REARRANGE_HAND") end
    end
    return upd(self,dt)
end

local gsr = Game.start_run
function Game:start_run(args)
    G.GAME.log = nil
    DejaVu.run_log = nil
    local ret = gsr(self,args)
    if args.savetext then
        DejaVu.log("CONTINUE_RUN")
    else
        local function get_deck_from_name(_name)
            for k, v in pairs(G.P_CENTERS) do
                if v.name == _name then return k end
            end
        end
        local run_prefix = G.P_CENTER_POOLS.Stake[G.GAME.stake].key.."|"..get_deck_from_name(G.GAME.selected_back.name).."|"..G.GAME.pseudorandom.seed.."|"..(G.GAME.challenge or '')
        local run_suffix = G.PROFILES[G.SETTINGS.profile].name.."|"..os.time(os.date("!*t"))
        DejaVu.log("START_RUN",run_prefix.."|"..run_suffix)
    end
    return ret
end

local gfsb = G.FUNCS.select_blind
G.FUNCS.select_blind = function(e)
    DejaVu.log("SELECT_BLIND")
    return gfsb(e)
end

local gfkb = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
    DejaVu.log("SKIP_BLIND")
    return gfkb(e)
end

local gfpcfh = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
    local selectedCardIndices = ""
    for i = 1, #G.hand.cards do
        if G.hand.cards[i].highlighted then
            selectedCardIndices = selectedCardIndices..i.."|"
        end
    end
    DejaVu.log("PLAY_HAND",selectedCardIndices)
    return gfpcfh(e)
end

local gfdcfh = G.FUNCS.discard_cards_from_highlighted
G.FUNCS.discard_cards_from_highlighted = function(e, hook)
    if not hook then
        local selectedCardIndices = ""
        for i = 1, #G.hand.cards do
            if G.hand.cards[i].highlighted then
                selectedCardIndices = selectedCardIndices..i.."|"
            end
        end
        DejaVu.log("DISCARD_HAND",selectedCardIndices)
    end
    return gfdcfh(e,hook)
end

local gfts = G.FUNCS.toggle_shop
G.FUNCS.toggle_shop = function(e)
    DejaVu.log("END_SHOP")
    return gfts(e)
end

local gfrs = G.FUNCS.reroll_shop
G.FUNCS.reroll_shop = function(e)
    DejaVu.log("REROLL_SHOP")
    return gfrs(e)
end

local gfsb = G.FUNCS.skip_booster
G.FUNCS.skip_booster = function(e)
    DejaVu.log("SKIP_BOOSTER_PACK")
    return gfsb(e)
end

local gfshs = G.FUNCS.sort_hand_suit
G.FUNCS.sort_hand_suit = function(e)
    DejaVu.log("SORT_SUIT")
    local ret = gfshs(e)
    DejaVu.sort_bypass = true
    return ret
end

local gfshv = G.FUNCS.sort_hand_value
G.FUNCS.sort_hand_value = function(e)
    DejaVu.log("SORT_RANK")
    local ret = gfshv(e)
    DejaVu.sort_bypass = true
    return ret
end

local gfbfs = G.FUNCS.buy_from_shop
G.FUNCS.buy_from_shop = function(e)
    local card = e.config.ref_table
    local area = card.area
    local pos = 0
    for i = 1, #area.cards do
        if area.cards[i] == card then pos = i end
    end
    if area == G.shop_jokers then
        DejaVu.log("BUY_CARD",pos)
    end
    if area == G.pack_cards then
        DejaVu.log("SELECT_BOOSTER_CARD",pos)
    end
    return gfbfs(e)
end
local gfuc = G.FUNCS.use_card
G.FUNCS.use_card = function(e)
    local card = e.config.ref_table
    local area = card.area
    if not area then
        DejaVu.log("USE_THIS_CARD")
    else
        local pos = 0
        for i = 1, #area.cards do
            if area.cards[i] == card then pos = i end
        end
        if area == G.shop_vouchers then
            DejaVu.log("BUY_VOUCHER",pos)
        end
        if area == G.shop_booster then
            DejaVu.log("BUY_BOOSTER",pos)
        end
        if area == G.consumeables then
            local selectedCardIndices = ""
            for i = 1, #G.hand.cards do
                if G.hand.cards[i].highlighted then
                    selectedCardIndices = selectedCardIndices..i.."|"
                end
            end
            DejaVu.log("USE_CONSUMABLE",pos.."|"..selectedCardIndices)
        end
        if area == G.pack_cards then
            local selectedCardIndices = ""
            for i = 1, #G.hand.cards do
                if G.hand.cards[i].highlighted then
                    selectedCardIndices = selectedCardIndices..i.."|"
                end
            end
            DejaVu.log("SELECT_BOOSTER_CARD",pos.."|"..selectedCardIndices)
        end
    end
    return gfuc(e)
end
local gfsc = G.FUNCS.sell_card
G.FUNCS.sell_card = function(e)
    local card = e.config.ref_table
    local area = card.area
    local pos = 0
    for i = 1, #area.cards do
        if area.cards[i] == card then pos = i end
    end
    if area == G.jokers then
        DejaVu.log("SELL_JOKER",pos)
    end
    if area == G.consumeables then
        DejaVu.log("SELL_CONSUMABLE",pos)
    end
    gfsc(e)
end

function G.FUNCS.ankh_show_seed(e)
DejaVu.save_to_file()
DejaVu.log("SHOW_SEED")
G.GAME.seeded = true
G.FUNCS:exit_overlay_menu()
G.FUNCS:options()
save_run()
end

local createOptionsRef = create_UIBox_options
function create_UIBox_options()
contents = createOptionsRef()
if G.STAGE == G.STAGES.RUN and not G.GAME.seeded then
    local show_seed_button = UIBox_button({
    minw = 5,
    button = "ankh_show_seed",
    label = {
    "Show Seed"
    }
    })
    table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, 2, show_seed_button)
end
return contents
end

function DejaVu.save_to_file()
    if not DejaVu.replay then
        local function get_deck_from_name(_name)
            for k, v in pairs(G.P_CENTERS) do
                if v.name == _name then return k end
            end
        end
        local function formatUnixTime(unixTime)
            local utcDiff = os.difftime(os.time(), os.time(os.date("!*t")))
            local localTime = unixTime + utcDiff
            return os.date("%b %d @ %H-%M-%S", localTime)
        end    
        local data = DejaVu.encode()
        if not nativefs.getInfo(lovely.mod_dir.."/MathIsFun0-Ankh/Runs") then nativefs.createDirectory(lovely.mod_dir.."/MathIsFun0-Ankh/Runs") end
        nativefs.write(lovely.mod_dir.."/MathIsFun0-Ankh/Runs/"..G.PROFILES[G.SETTINGS.profile].name.."_"..localize{type = 'name_text', set = 'Back', key = G.P_CENTERS[get_deck_from_name(G.GAME.selected_back.name)].key}.."_"..(G.GAME.seeded and G.GAME.pseudorandom.seed or formatUnixTime(os.time(os.date("!*t"))))..".ankh",data)
    end
end

function DejaVu.encode()
    local function byte_swap(data)
        local swapped = {}
        for i = 1, #data - 1, 2 do
            swapped[#swapped + 1] = data:sub(i + 1, i + 1) .. data:sub(i, i)
        end
        if #data % 2 == 1 then
            swapped[#swapped + 1] = data:sub(#data, #data)
        end
        return table.concat(swapped)
    end
    local function extract_bit(byte, position)
        local mask = 2 ^ position
        return (byte % (mask * 2) >= mask) and 1 or 0
    end
    local function set_bit(byte, position, bit)
        local mask = 2 ^ position
        if bit == 1 then
            if byte % (mask * 2) < mask then
                byte = byte + mask
            end
        else
            if byte % (mask * 2) >= mask then
                byte = byte - mask
            end
        end
        return byte
    end
    local function bit_swap(data)
        local swapped = {}
        for i = 1, #data do
            local byte = string.byte(data, i)
            local swapped_byte = 0
            for j = 0, 7 do
                local bit = extract_bit(byte, j)
                if j % 2 == 0 then
                    swapped_byte = set_bit(swapped_byte, j + 1, bit)
                else
                    swapped_byte = set_bit(swapped_byte, j - 1, bit)
                end
            end
            table.insert(swapped, string.char(swapped_byte))
        end
        return table.concat(swapped)
    end
    return byte_swap(bit_swap(love.data.compress("string","gzip",DejaVu.run_log)))
end

function DejaVu.decode(data, from_save_load)
    local function byte_swap(data)
        local swapped = {}
        for i = 1, #data - 1, 2 do
            swapped[#swapped + 1] = data:sub(i + 1, i + 1) .. data:sub(i, i)
        end
        if #data % 2 == 1 then
            swapped[#swapped + 1] = data:sub(#data, #data)
        end
        return table.concat(swapped)
    end
    local function extract_bit(byte, position)
        local mask = 2 ^ position
        return (byte % (mask * 2) >= mask) and 1 or 0
    end
    local function set_bit(byte, position, bit)
        local mask = 2 ^ position
        if bit == 1 then
            if byte % (mask * 2) < mask then
                byte = byte + mask
            end
        else
            if byte % (mask * 2) >= mask then
                byte = byte - mask
            end
        end
        return byte
    end
    local function bit_swap(data)
        local swapped = {}
        for i = 1, #data do
            local byte = string.byte(data, i)
            local swapped_byte = 0
            for j = 0, 7 do
                local bit = extract_bit(byte, j)
                if j % 2 == 0 then
                    swapped_byte = set_bit(swapped_byte, j + 1, bit)
                else
                    swapped_byte = set_bit(swapped_byte, j - 1, bit)
                end
            end
            table.insert(swapped, string.char(swapped_byte))
        end
        return table.concat(swapped)
    end
    local function split_string(input, delimiter)
        local result = {}
        for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
            table.insert(result, match)
        end
        return result
    end
    local function process_multiline_input(input)
        local lines = split_string(input, "\n")
        local result = {}

        for _, line in ipairs(lines) do
            local number_part = line:match("^(.-) %-")
            local delimited_part = line:match("%- (.+)")
            if number_part and delimited_part then
                local components = split_string(delimited_part, "|")
                local combined = {number_part}
                for _, component in ipairs(components) do
                    table.insert(combined, component)
                end
                table.insert(result, combined)
            end
        end
        return result
    end
    local result, data = pcall(function() return love.data.decompress("string","gzip",bit_swap(byte_swap(data))) end)
    if not result then return end
    if from_save_load == true then
        return data
    end
    return process_multiline_input(data)
end