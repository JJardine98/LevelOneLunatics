-- Namespace frame
local LOL = CreateFrame("Frame")
local addonName = "LOL"

-- SavedVariables
LOL_PlayerDB = LOL_PlayerDB or {}
LOL_GuildDB = LOL_GuildDB or {}

-- Helper: per-character DB
local function PlayerDB()
    local name = UnitName("player")
    LOL_PlayerDB[name] = LOL_PlayerDB[name] or { hk = 0, quests = 0 }
    return LOL_PlayerDB[name]
end

-- Helper: chat output
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..addonName.."]|r "..msg)
end

-- Slash commands
SLASH_LOLSTATS1 = "/lolstats"
SlashCmdList["LOLSTATS"] = function()
    local db = PlayerDB()
    Print("Stats — HK: "..db.hk.." | Quests: "..db.quests)
end

SLASH_LOLTEST1 = "/loltest"
SlashCmdList["LOLTEST"] = function(msg)
    local db = PlayerDB()
    if msg == "hk" then
        db.hk = db.hk + 1
        Print("Test HK added! Total: "..db.hk)
    else
        db.quests = db.quests + 1
        Print("Test Quest added! Total: "..db.quests)
    end
end

-- =========================
-- Event dispatcher (Vanilla-safe with debug)
-- =========================
LOL:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    local db = PlayerDB()

    if event == "PLAYER_ENTERING_WORLD" then
        Print("Addon loaded. /lolstats to view stats, /loltest hk or /loltest to increment manually.")

    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        local msg = arg1
        Print("|cff00ff00[LOL-DEBUG HK]|r "..tostring(msg))
        -- Example detection:
        -- if msg:find("honorable kill") then
        --     db.hk = db.hk + 1
        --     Print("Honorable Kill! Total: "..db.hk)
        -- end

    elseif event == "QUEST_COMPLETE" then
        -- Quest turned in
        Print("|cff00ff00[LOL-DEBUG QUEST]|r Quest turned in")
        -- Increment manually for testing:
        -- db.quests = db.quests + 1
        -- Print("Quest completed! Total: "..db.quests)
    end
end)

-- Register Turtle-friendly events
LOL:RegisterEvent("PLAYER_ENTERING_WORLD")
LOL:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
LOL:RegisterEvent("QUEST_COMPLETE")