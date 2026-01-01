-- =========================
-- Databases
-- =========================
LOL_PlayerDB = LOL_PlayerDB or {}
LOL_GuildDB = LOL_GuildDB or {}

if not LOL_GuildDB.players then
    LOL_GuildDB.players = {}
end

-- =========================
-- Initialize Player Stats
-- =========================
local function InitPlayer()
    if not LOL_PlayerDB.stats then
        LOL_PlayerDB.stats = { hk = 0, quests = 0 }
    end
end

-- =========================
-- Simple Stats Display
-- =========================
SLASH_LOLSTATS1 = "/lolstats"
SlashCmdList["LOLSTATS"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL] Your Stats:|r")
    if LOL_PlayerDB.stats then
        DEFAULT_CHAT_FRAME:AddMessage("HK: " .. LOL_PlayerDB.stats.hk .. " | Quests: " .. LOL_PlayerDB.stats.quests)
    else
        DEFAULT_CHAT_FRAME:AddMessage("No stats yet!")
    end
end

-- =========================
-- Test Commands
-- =========================
SLASH_LOLTEST1 = "/loltest"
SlashCmdList["LOLTEST"] = function(msg)
    if not LOL_PlayerDB.stats then InitPlayer() end
    if msg == "hk" then
        LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Test HK added! Total: " .. LOL_PlayerDB.stats.hk)
    else
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Test quest added! Total: " .. LOL_PlayerDB.stats.quests)
    end
end

-- =========================
-- Event Frame
-- =========================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")

eventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        InitPlayer()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Loaded! /loltest, /loltest hk, /lolstats")

    elseif event == "QUEST_TURNED_IN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Quest completed! Total: " .. LOL_PlayerDB.stats.quests)
        
    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Honorable Kill! Total: " .. LOL_PlayerDB.stats.hk)
    end
end)