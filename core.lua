-- Addon namespace
local addonName = ...
local LOL = CreateFrame("Frame")

-- SavedVariables (pfUI‑style)
LOL_DB = LOL_DB or {}

-- Ensure per‑character table
local function PlayerDB()
    local name = UnitName("player")
    LOL_DB[name] = LOL_DB[name] or { hk = 0, quests = 0 }
    return LOL_DB[name]
end

-- Pretty print
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..addonName.."]|r "..msg)
end

-- Slash commands (pfUI‑style)
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

-- Event dispatcher (pfUI‑style)
LOL:SetScript("OnEvent", function(self, event, ...)
    local db = PlayerDB()

    if event == "PLAYER_LOGIN" then
        Print("Loaded. /lol to view stats. Use /lol reset to reset.")

    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        local msg = ...
        if msg and msg:find("honorable") then
            db.hk = db.hk + 1
            Print("Honorable kill! Total: "..db.hk)
        end

    elseif event == "QUEST_COMPLETE" then
        db.quests = db.quests + 1
        Print("Quest completed! Total: "..db.quests)
    end
end)

-- Register events (pfUI‑style)
LOL:RegisterEvent("PLAYER_LOGIN")
LOL:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
LOL:RegisterEvent("QUEST_COMPLETE")
