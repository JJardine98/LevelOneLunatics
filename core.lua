-- =========================
-- Databases
-- =========================
LOL_PlayerDB = LOL_PlayerDB or {}

local playerName = UnitName("player")

local function Stats()
    LOL_PlayerDB[playerName] = LOL_PlayerDB[playerName] or {
        hk = 0,
        quests = 0,
        created = time()
    }
    return LOL_PlayerDB[playerName]
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
    local s = Stats()
    LOL_Print("Your Stats — HK: "..s.hk.." | Quests: "..s.quests)
end

SLASH_LOLTEST1 = "/loltest"
SlashCmdList["LOLTEST"] = function(msg)
    local s = Stats()
    if msg == "hk" then
        s.hk = s.hk + 1
        LOL_Print("Test HK added! Total: "..s.hk)
    else
        s.quests = s.quests + 1
        LOL_Print("Test Quest added! Total: "..s.quests)
    end
end

-- =========================
-- Event Frame
-- =========================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")

f:SetScript("OnEvent", function(self, event, msg)
    if event == "PLAYER_ENTERING_WORLD" then
        Stats()
        LOL_Print("Loaded. Use /lolstats")

    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        if string.find(msg or "", "honorable") then
            local s = Stats()
            s.hk = s.hk + 1
            LOL_Print("Honorable Kill! Total: "..s.hk)
        end
    end
end)

-- =========================
-- Quest Turn-In Hook (Vanilla)
-- =========================
local OldGetQuestReward = GetQuestReward
function GetQuestReward(...)
    local s = Stats()
    s.quests = s.quests + 1
    LOL_Print("Quest completed! Total: "..s.quests)
    return OldGetQuestReward(...)
end
