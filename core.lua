-- =========================
-- Databases
-- =========================
LOL_PlayerDB = LOL_PlayerDB or {}
LOL_GuildDB = LOL_GuildDB or { players = {} }

local playerName = UnitName("player")

-- =========================
-- Initialize Player Stats per character
-- =========================
local function InitPlayer()
    if not LOL_PlayerDB[playerName] then
        LOL_PlayerDB[playerName] = {
            stats = {
                hk = 0,
                questsCompleted = 0
            }
        }
    end
end

-- =========================
-- Slash Commands
-- =========================
SLASH_LOLSTATS1 = "/lolstats"
SlashCmdList["LOLSTATS"] = function()
    InitPlayer()
    local stats = LOL_PlayerDB[playerName].stats
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL] Your Stats:|r")
    DEFAULT_CHAT_FRAME:AddMessage("HK: " .. stats.hk .. " | Quests Completed: " .. stats.questsCompleted)
end

SLASH_LOLTEST1 = "/loltest"
SlashCmdList["LOLTEST"] = function(msg)
    InitPlayer()
    local stats = LOL_PlayerDB[playerName].stats
    if msg == "hk" then
        stats.hk = stats.hk + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Test HK added! Total: " .. stats.hk)
    else
        stats.questsCompleted = stats.questsCompleted + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Test quest added! Total: " .. stats.questsCompleted)
    end
end

-- =========================
-- Quest Log Tracking (PFQuest-style)
-- =========================
local function UpdateQuests()
    InitPlayer()
    local completed = 0
    local numQuests = GetNumQuestLogEntries()

    for i = 1, numQuests do
        local title, level, _, isHeader, isComplete = GetQuestLogTitle(i)
        if not isHeader and isComplete == 1 then
            completed = completed + 1
        end
    end

    -- Only increment if new completions
    if completed > LOL_PlayerDB[playerName].stats.questsCompleted then
        local newCompleted = completed - LOL_PlayerDB[playerName].stats.questsCompleted
        LOL_PlayerDB[playerName].stats.questsCompleted = completed
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r " .. newCompleted .. " new quest(s) detected! Total: " .. completed)
    end
end

-- =========================
-- Event Frame
-- =========================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE") -- fires whenever the quest log changes

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "PLAYER_ENTERING_WORLD" then
        InitPlayer()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Addon loaded! Use /lolstats or /loltest hk")
        UpdateQuests()
    elseif event == "QUEST_LOG_UPDATE" then
        UpdateQuests()
    end
end)
