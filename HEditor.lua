--------------------[ Heist Editor ]--------------------
--- Cluckin Bell, KnoWay, Dr Dre, and Oscar Guzman prep skips
--- Cayo Perico editor
--- Doomsday Act setter
---
--- v0:
--- - Created
--------------------------------------------------------

--------------------( Basic Module )--------------------
---@class HeistInfo
---@field public name string
---@field public stat {name: string, val: integer}
---@field public opt_info? string Optional info to provide to a tooltip, typically a starting requirement that needs to be done manually

---@alias HEIST_TYPES table<integer, HeistInfo>

---@type HEIST_TYPES
local HEIST_TYPES = {
    {
        name = "Cluckin Bell",
        stat = {
            name = "MPX_SALV23_INST_PROG",
            val = 31,
        },
    },
    {
        name = "KnoWay Out",
        stat = {
            name = "MPX_M25_AVI_MISSION_CURRENT",
            val = 4,
        },
    },
    {
        name = "Dr Dre Contract",
        stat = {
            name = "MPXstring.formatIXER_STORY_BS",
            val = 4095,
        }
    },
    {
        name = "Oscar Guzman",
        stat = {
            name = "MPX_HACKER24_INST_BS",
            val = 31,
        },
        opt_info = "Complete first mission on Hard first!"
    },
}

local function drawBasicTab()
    for i, heist in ipairs(HEIST_TYPES) do
        local heist_name = heist.name
        local is_done = stats.get_int(heist.stat.name) == heist.stat.val

        ImGui.PushID(i)
        ImGui.SeparatorText(heist_name)

        ImGui.BeginDisabled(is_done)
        if ImGui.Button("Skip Preps") then
            stats.set_int(heist.stat.name, heist.stat.val)
            gui.show_success(heist_name, "All preps skipped!")
        end
        if (heist.opt_info and not is_done) then
            if (ImGui.IsItemHovered()) then
                ImGui.BeginTooltip()
                ImGui.PushTextWrapPos(ImGui.GetFontSize() * 25)
                ImGui.TextWrapped(heist.opt_info)
                ImGui.PopTextWrapPos()
                ImGui.EndTooltip()
            end
        end
        ImGui.EndDisabled()
        ImGui.PopID()

        ImGui.Spacing()
    end
end

--------------------------------------------------------

--------------------( Cayo  Module )--------------------
local secondary_targets = { "CASH", "WEED", "COKE", "GOLD" }
local cayo_secondary_target_i, cayo_secondary_target_c

---@class Cayo
local Cayo = {}

-- https://www.unknowncheats.me/forum/4489469-post16.html
---@param type string
---@param index integer
local function setSecondaryTargets(type, index)
    local targets = { 0, 0, 0, 0 }
    targets[index] = -1

    for st = 1, 4 do
        local stat_name = string.format("MPX_H4LOOT_%s_%s", secondary_targets[st], type)
        stats.set_int(stat_name, targets[st])
        stats.set_int(string.format("%s_SCOPED", stat_name), targets[st])
    end

    stats.set_int("MPX_H4LOOT_PAINT", -1) -- Not really any reason to have an option for paintings
    stats.set_int("MPX_H4LOOT_PAINT_SCOPED", -1)
end

---@return integer, integer
local function getSecondaryTargets()
    local loot_i, loot_c

    for st = 1, 4 do
        local stat_name = string.format("MPX_H4LOOT_%s", secondary_targets[st])
        if (stats.get_int(string.format("%s_I", stat_name)) == -1) then
            loot_i = st - 1 -- ImGui indexes by 0
        end
        if (stats.get_int(string.format("%s_C", stat_name)) == -1) then
            loot_c = st - 1
        end
    end

    return loot_i or -1, loot_c or -1
end

local function drawCayoTab()
    -- https://www.unknowncheats.me/forum/grand-theft-auto-v/695454-edit-cayo-perico-primary-target-stat-yimmenu-v2.html
    -- https://www.unknowncheats.me/forum/grand-theft-auto-v/431801-cayo-perico-heist-click.html
    local cayo_heist_primary         = stats.get_int("MPX_H4CNF_TARGET")
    local cayo_heist_difficulty      = stats.get_int("MPX_H4_PROGRESS")
    local cayo_heist_weapons         = stats.get_int("MPX_H4CNF_WEAPONS")
    local cayo_cooldown              = stats.get_int("MPX_H4_COOLDOWN")
    local cayo_cooldown_hard         = stats.get_int("MPX_H4_COOLDOWN_HARD")

    local epochNow                   = os.time()
    local cooldown_seconds_left      = cayo_cooldown - epochNow
    local cooldown_hard_seconds_left = cayo_cooldown_hard - epochNow
    local on_cooldown                = (cooldown_seconds_left > 0) or (cooldown_hard_seconds_left > 0)

    if (on_cooldown) then
        local seconds_left = cooldown_seconds_left > 0 and cooldown_seconds_left or cooldown_hard_seconds_left
        ImGui.SeparatorText(string.format("On cooldown for %.2f seconds", seconds_left))
    end

    ImGui.BeginDisabled(on_cooldown)
    ImGui.SeparatorText("Setup")

    ImGui.SetNextItemWidth(ImGui.GetFontSize() * 10)
    local new_primary_target, primary_target_clicked = ImGui.Combo(
        "Primary Target",
        cayo_heist_primary,
        { "Tequila", "Ruby", "Bearer Bonds", "Pink Diamond", "Madrazo Files", "Panther Statue" },
        6
    )

    if (primary_target_clicked) then
        stats.set_int("MPX_H4CNF_TARGET", new_primary_target)
    end

    ImGui.Spacing()

    ImGui.SetNextItemWidth(ImGui.GetFontSize() * 10)
    local secondary_target_click
    cayo_secondary_target_i, secondary_target_click = ImGui.Combo(
        "Secondary Targets (Island)",
        cayo_secondary_target_i,
        secondary_targets,
        4
    )

    if (secondary_target_click) then
        setSecondaryTargets("I", cayo_secondary_target_i + 1)
    end

    ImGui.SetNextItemWidth(ImGui.GetFontSize() * 10)
    cayo_secondary_target_c, secondary_target_click = ImGui.Combo(
        "Secondary Targets (Compound)",
        cayo_secondary_target_c,
        secondary_targets,
        4
    )

    if (secondary_target_click) then
        setSecondaryTargets("C", cayo_secondary_target_c + 1)
    end

    ImGui.Spacing()

    ImGui.SetNextItemWidth(ImGui.GetFontSize() * 10)
    local new_weapons, weapons_clicked = ImGui.Combo(
        "Weapon Loadout",
        cayo_heist_weapons,
        { "Unselected", "Aggressor", "Conspirator", "Crackshot", "Saboteur", "Marksman" },
        6
    )

    if (weapons_clicked) then
        stats.set_int("MPX_H4CNF_WEAPONS", new_weapons)
    end

    ImGui.SeparatorText("Options")

    local new_difficulty, difficulty_toggled = ImGui.Checkbox("Hard Mode",
        cayo_heist_difficulty > 130000
    )

    if (difficulty_toggled) then
        if (new_difficulty) then
            stats.set_int("MPX_H4_PROGRESS", 131055)
        else
            stats.set_int("MPX_H4_PROGRESS", 126823)
        end
    end

    -- https://www.unknowncheats.me/forum/3058973-post602.html
    if ImGui.Button("Unlock All Heist Options") then
        stats.set_int("MPX_H4CNF_WEP_DISRP", 3)
        stats.set_int("MPX_H4CNF_ARM_DISRP", 3)
        stats.set_int("MPX_H4CNF_HEL_DISRP", 3)
        stats.set_int("MPX_H4CNF_BS_GEN", 131071)
        stats.set_int("MPX_H4CNF_BS_ENTR", 63)
        stats.set_int("MPX_H4CNF_BS_ABIL", 63)
        stats.set_int("MPX_H4_MISSIONS", 65535)
        stats.set_int("MPX_H4_PLAYTHROUGH_STATUS", 40000)
    end

    ImGui.EndDisabled() -- on_cooldown
end

--------------------------------------------------------

--------------------( Dday  Module )--------------------
---@class DdayHeistInfo : HeistInfo
---@field public stat {status: integer, flow: integer}

---@alias DDAY_HEIST_TYPES table<integer, DdayHeistInfo>

---@type DDAY_HEIST_TYPES
local DDAY_HEIST_TYPES = {
    {
        name = "The Data Breaches",
        stat = {
            status = 229383,
            flow = 503,
        }
    },
    {
        name = "The Bogdan Problem",
        stat = {
            status = 229378,
            flow = 240,
        }
    },
    {
        name = "The Doomsday Scenario",
        stat = {
            status = 229380,
            flow = 16368,
        }
    },
}

-- Help text and values copied from: https://www.unknowncheats.me/forum/grand-theft-auto-v/431801-cayo-perico-heist-click.html
local function drawDdayTab()
    local dday_status           = stats.get_int("MPX_GANGOPS_HEIST_STATUS")
    local dday_cooldown         = stats.get_int("MPX_GANGOPS_LAUNCH_TIME")

    local epochNow              = os.time()
    local cooldown_seconds_left = dday_cooldown - epochNow
    local on_cooldown           = cooldown_seconds_left > 0

    if (on_cooldown) then
        ImGui.SeparatorText(string.format("On cooldown for %.2f seconds", cooldown_seconds_left))
    end

    ImGui.BeginDisabled(on_cooldown)
    ImGui.SeparatorText("IMPORTANT")
    ImGui.TextWrapped(
        "This method is necessary if you have never played Doomsday as a host. If you have already played and completed some heists as host, skip this step.")
    local button_label = "FORCE RESET"
    if (ImGui.Button(button_label)) then
        stats.set_int("MPX_GANGOPS_HEIST_STATUS", 9999)
    end
    ImGui.TextWrapped(string.format("Press the '%s' button, then call Lester to cancel all 3 heists for Doomsday.",
        button_label))

    ImGui.SeparatorText("Heist Setup")

    for _, act in ipairs(DDAY_HEIST_TYPES) do
        ImGui.BeginDisabled(dday_status == act.stat.status)
        if (ImGui.Button(act.name)) then
            stats.set_int("MPX_GANGOPS_HEIST_STATUS", act.stat.status)
            stats.set_int("MPX_GANGOPSstring.formatLOW_MISSION_PROG", act.stat.flow)
            stats.set_int("MPX_GANGOPSstring.formatLOW_NOTIFICATIONS", 1557)
        end
        ImGui.EndDisabled()
    end
    ImGui.EndDisabled() -- on_cooldown
end

--------------------------------------------------------

--------------------( Main  Script )--------------------
if (type(script["run_in_callback"]) == "function") then
    local errmsg = "YimMenuV2 is not supported. If you want to run this script in GTA V Enhanced, download YimLuaAPI."
    ---@diagnostic disable-next-line: undefined-global
    notify.error("Heist Editor", errmsg)
    error(errmsg .. "  https://github.com/TupoyeMenu/YimLuaAPI")
end

gui.add_tab("Heist Editor")
    :add_imgui(function()
        local isOnline = NETWORK.NETWORK_IS_SESSION_STARTED() and
            not NETWORK.NETWORK_IS_IN_TRANSITION() and
            not STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()

        if (isOnline) then
            if (not cayo_secondary_target_i or not cayo_secondary_target_c) then
                cayo_secondary_target_i, cayo_secondary_target_c = getSecondaryTargets()
            end

            if (ImGui.BeginTabBar("##htabs")) then
                if (ImGui.BeginTabItem("Basic")) then
                    drawBasicTab()
                    ImGui.EndTabItem()
                end
                if (ImGui.BeginTabItem("Cayo")) then
                    drawCayoTab()
                    ImGui.EndTabItem()
                end
                if (ImGui.BeginTabItem("Dday")) then
                    drawDdayTab()
                    ImGui.EndTabItem()
                end
                ImGui.EndTabBar()
            end
        else
            ImGui.Text("Waiting for Online...")
        end
    end)
