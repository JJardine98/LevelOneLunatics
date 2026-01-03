-- Namespace
local LOL = CreateFrame("Frame")
local addonName = "LOL"

-- SavedVariables
LOL_DB = LOL_DB or {}

-- Per-character stats
local function PlayerDB()
    local name = UnitName("player")
    LOL_DB[name] = LOL_DB[name] or { hk = 0, quests = 0 }
    return LOL_DB[name]
end

-- Chat output
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..addonName.."]|r "..msg)
end

-- Slash command
SLASH_LOL1 = "/lol"
SlashCmdList["LOL"] = function(cmd)
    local db = PlayerDB()
    if cmd == "reset" then
        db.hk = 0
        db.quests = 0
        Print("Stats reset.")
        return
    end
    Print("HK: "..db.hk.." | Quests: "..db.quests)
end

-- Event dispatcher
LOL:SetScript("OnEvent", function(self, event, ...)
    local db = PlayerDB()

    if event == "PLAYER_LOGIN" then
        Print("Loaded. /lol to view stats. /lol reset to reset.")

    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        local msg = ...
        if msg and msg:find("honorable") then
            db.hk = db.hk + 1
            Print("Honorable kill! Total: "..db.hk)
        end
    end
end)

-- Quest hook (Vanilla)
local OldGetQuestReward = GetQuestReward
function GetQuestReward(...)
    local db = PlayerDB()
    db.quests = db.quests + 1
    Print("Quest completed! Total: "..db.quests)
    return OldGetQuestReward(...)
end

-- Register events
LOL:RegisterEvent("PLAYER_LOGIN")
LOL:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
