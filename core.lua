-- =========================
-- Databases
-- =========================
LOL_PlayerDB = LOL_PlayerDB or {}
LOL_GuildDB  = LOL_GuildDB  or { players = {} }

local playerName = UnitName("player")

-- =========================
-- Initialize Player Stats
-- =========================
local function InitPlayer()
    if not LOL_PlayerDB.stats then
        LOL_PlayerDB.stats = {
            hk = 0,
            quests = 0,
            created = time()
        }
    end
end

-- =========================
-- Chat Output
-- =========================
local function LOL_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r " .. msg)
end

-- =========================
-- Slash Commands
-- =========================
SLASH_LOLSTATS1 = "/lolstats"
SlashCmdList["LOLSTATS"] = function()
    InitPlayer()
    LOL_Print("Your Stats — HK: "..LOL_PlayerDB.stats.hk.." | Quests: "..LOL_PlayerDB.stats.quests)
end

SLASH_LOLTEST1 = "/loltest"
SlashCmdList["LOLTEST"] = function(msg)
    InitPlayer()
    if msg == "hk" then
        LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
        LOL_Print("Test HK added! Total: "..LOL_PlayerDB.stats.hk)
    else
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        LOL_Print("Test Quest added! Total: "..LOL_PlayerDB.stats.quests)
    end
end

-- =========================
-- Event Frame
-- =========================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("QUEST_COMPLETE")
f:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")

f:SetScript("OnEvent", function(self, event, msg)
    if event == "PLAYER_ENTERING_WORLD" then
        InitPlayer()
        LOL_Print("Loaded. Use /lolstats")

    elseif event == "QUEST_COMPLETE" then
        InitPlayer()
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        LOL_Print("Quest completed! Total: "..LOL_PlayerDB.stats.quests)

    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        if string.find(msg or "", "honorable") then
            InitPlayer()
            LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
            LOL_Print("Honorable Kill! Total: "..LOL_PlayerDB.stats.hk)
        end
    end
end)
