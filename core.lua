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
-- Genesis UI
-- =========================
local function ShowGenesisUI()
    if LOL_PlayerDB.genesisLocked then return end
    if LOL_GenesisFrame then return end

    local frame = CreateFrame("Frame", "LOL_GenesisFrame", UIParent)
    frame:SetWidth(250)
    frame:SetHeight(140)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Enter Legacy Stats")

    local hkLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hkLabel:SetPoint("TOP", 0, -40)
    hkLabel:SetText("Honorable Kills:")

    local hkBox = CreateFrame("EditBox", "LOL_HKBox", frame, "InputBoxTemplate")
    hkBox:SetWidth(100)
    hkBox:SetHeight(25)
    hkBox:SetPoint("TOP", 0, -55)
    hkBox:SetAutoFocus(false)
    hkBox:SetText("0")
    hkBox:SetScript("OnChar", function()
        local text = this:GetText()
        if not tonumber(text) then
            this:SetText(string.sub(text, 1, -2))
        end
    end)

    local questLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    questLabel:SetPoint("TOP", hkBox, "BOTTOM", 0, -10)
    questLabel:SetText("Quests Completed:")

    local questBox = CreateFrame("EditBox", "LOL_QuestBox", frame, "InputBoxTemplate")
    questBox:SetWidth(100)
    questBox:SetHeight(25)
    questBox:SetPoint("TOP", questLabel, "BOTTOM", 0, -5)
    questBox:SetAutoFocus(false)
    questBox:SetText("0")
    questBox:SetScript("OnChar", function()
        local text = this:GetText()
        if not tonumber(text) then
            this:SetText(string.sub(text, 1, -2))
        end
    end)

    local btn = CreateFrame("Button", "LOL_SaveButton", frame, "UIPanelButtonTemplate")
    btn:SetWidth(120)
    btn:SetHeight(25)
    btn:SetPoint("BOTTOM", 0, 15)
    btn:SetText("Save Legacy Stats")
    btn:SetScript("OnClick", function()
        LOL_PlayerDB.legacy = {
            hk = tonumber(LOL_HKBox:GetText()) or 0,
            quests = tonumber(LOL_QuestBox:GetText()) or 0
        }
        LOL_PlayerDB.genesisLocked = true
        LOL_GenesisFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Legacy stats saved and locked!")
        SendStats()
    end)

    frame:Show()
end

-- =========================
-- Leaderboard UI
-- =========================
local LOL_UI = CreateFrame("Frame", "LOL_LeaderboardFrame", UIParent)
LOL_UI:SetWidth(350)
LOL_UI:SetHeight(400)
LOL_UI:SetPoint("CENTER")
LOL_UI:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
LOL_UI:EnableMouse(true)
LOL_UI:SetMovable(true)
LOL_UI:RegisterForDrag("LeftButton")
LOL_UI:SetScript("OnDragStart", function() this:StartMoving() end)
LOL_UI:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
LOL_UI:Hide()

local title = LOL_UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -15)
title:SetText("Level One Lunatics Stats")

local scrollFrame = CreateFrame("ScrollFrame", "LOL_ScrollFrame", LOL_UI, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", LOL_UI, "TOPLEFT", 15, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", LOL_UI, "BOTTOMRIGHT", -30, 15)

local content = CreateFrame("Frame", "LOL_Content", scrollFrame)
content:SetWidth(300)
content:SetHeight(1)
scrollFrame:SetScrollChild(content)

function LOL_UI:Update()
    local i
    if content.children then
        for i = 1, table.getn(content.children) do
            if content.children[i] then
                content.children[i]:Hide()
            end
        end
    end
    content.children = {}

    local yPos = -5
    local name, stats
    for name, stats in pairs(LOL_GuildDB.players) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetWidth(280)
        btn:SetHeight(20)
        btn:SetPoint("TOPLEFT", 5, yPos)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        
        local displayText = string.format("%s | HK: %d | Quests: %d", name, stats.hk, stats.quests)
        btn:SetText(displayText)

        btn:SetScript("OnClick", function()
            local msg = "|cff00ff00[LOL]|r Player: " .. name .. " | HK: " .. stats.hk .. " | Quests: " .. stats.quests
            DEFAULT_CHAT_FRAME:AddMessage(msg)
        end)

        btn:Show()
        table.insert(content.children, btn)
        yPos = yPos - 25
    end
    
    local newHeight = -yPos + 5
    if newHeight < 1 then newHeight = 1 end
    content:SetHeight(newHeight)
end

SLASH_LOLUI1 = "/lolui"
SlashCmdList["LOLUI"] = function()
    if LOL_UI:IsShown() then
        LOL_UI:Hide()
    else
        LOL_UI:Show()
        LOL_UI:Update()
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
        ShowGenesisUI()
        local hubList = ""
        local i
        for i = 1, table.getn(LOL_GuildDB.hubs) do
            if i > 1 then
                hubList = hubList .. ", "
            end
            hubList = hubList .. LOL_GuildDB.hubs[i]
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LOL]|r Guild stats tracking active! Hubs: " .. hubList)

    elseif event == "QUEST_TURNED_IN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        SendStats()

    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
        SendStats()

    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == "LOL" and arg2 and arg4 then
            local nameOnly = string.gsub(arg4, "%-.*", "")
            ReceiveStats(nameOnly, arg2)
        end

    elseif event == "PLAYER_LOGOUT" then
        SendStats()
    end
end)