-- =========================
-- Databases
-- =========================
LOL_PlayerDB = LOL_PlayerDB or {}
LOL_GuildDB  = LOL_GuildDB  or {}

if not LOL_GuildDB.players then
    LOL_GuildDB.players = {}
end

if not LOL_GuildDB.hubs then
    LOL_GuildDB.hubs = { "Solutions", "AltHub1", "AltHub2" }
end

local playerName = UnitName("player")

-- =========================
-- Initialize Player Stats
-- =========================
local function InitPlayer()
    if not LOL_PlayerDB.stats then
        LOL_PlayerDB.stats = { hk = 0, quests = 0 }
    end
end

-- =========================
-- Pick Active Hub
-- =========================
local function PickActiveHub()
    if not IsInGuild() then return nil end
    GuildRoster()
    local numTotal = GetNumGuildMembers()
    local i, hubIndex
    for hubIndex = 1, table.getn(LOL_GuildDB.hubs) do
        local hubName = LOL_GuildDB.hubs[hubIndex]
        for i = 1, numTotal do
            local name, rank, subgroup, level, class, zone, note, officernote, online = GetGuildRosterInfo(i)
            if name == hubName and online then
                return hubName
            end
        end
    end
    return nil
end

-- =========================
-- Hub / Sync Functions
-- =========================
local function SendStats()
    if not LOL_PlayerDB.stats then InitPlayer() end
    
    local legacyHK = 0
    local legacyQuests = 0
    if LOL_PlayerDB.legacy then
        legacyHK = LOL_PlayerDB.legacy.hk or 0
        legacyQuests = LOL_PlayerDB.legacy.quests or 0
    end
    
    local hk = LOL_PlayerDB.stats.hk + legacyHK
    local quests = LOL_PlayerDB.stats.quests + legacyQuests
    local timestamp = time()
    local msg = hk .. "," .. quests .. "," .. timestamp

    local activeHub = PickActiveHub()
    if activeHub == playerName then
        LOL_GuildDB.players[playerName] = { hk = hk, quests = quests, timestamp = timestamp }
    elseif activeHub then
        SendAddonMessage("LOL", msg, "WHISPER", activeHub)
    end
end

local function ReceiveStats(sender, msg)
    if not sender or not msg then return end
    local parts = {}
    local count = 0
    for part in string.gmatch(msg, "([^,]+)") do
        count = count + 1
        parts[count] = part
    end
    if count < 3 then return end
    local hk = tonumber(parts[1])
    local quests = tonumber(parts[2])
    local ts = tonumber(parts[3])
    if not hk or not quests or not ts then return end

    local existing = LOL_GuildDB.players[sender]
    if not existing or ts > (existing.timestamp or 0) then
        LOL_GuildDB.players[sender] = { hk = hk, quests = quests, timestamp = ts }
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
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL] Guild Stats:|r")
    for name, stats in pairs(LOL_GuildDB.players) do
        DEFAULT_CHAT_FRAME:AddMessage(name .. " - HK: " .. stats.hk .. " | Quests: " .. stats.quests)
    end
end

-- =========================
-- Reset Command
-- =========================
SLASH_LOLRESET1 = "/lolreset"
SlashCmdList["LOLRESET"] = function()
    LOL_PlayerDB = {}
    LOL_GuildDB = {}
    LOL_GuildDB.players = {}
    LOL_GuildDB.hubs = { "Solutions", "AltHub1", "AltHub2" }
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Player and guild stats have been reset!")
end

-- =========================
-- Event Frame
-- =========================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        RegisterAddonMessagePrefix("LOL")
        InitPlayer()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Stats tracking active! Type /lolstats to view stats.")

    elseif event == "QUEST_TURNED_IN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        SendStats()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Quest completed! Total: " .. LOL_PlayerDB.stats.quests)

    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
        SendStats()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Honorable Kill! Total: " .. LOL_PlayerDB.stats.hk)

    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == "LOL" and arg2 and arg4 then
            local nameOnly = string.gsub(arg4, "%-.*", "")
            ReceiveStats(nameOnly, arg2)
        end

    elseif event == "PLAYER_LOGOUT" then
        SendStats()
    end
end)