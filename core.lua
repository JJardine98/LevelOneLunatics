-- =========================
-- Databases
-- =========================
LOL_PlayerDB = LOL_PlayerDB or {}
LOL_GuildDB  = LOL_GuildDB  or { players = {}, hubs = { "Solutions", "AltHub1", "AltHub2" } }

local playerName = UnitName("player")

-- =========================
-- Initialize Player Stats
-- =========================
local function InitPlayer()
    LOL_PlayerDB.stats = LOL_PlayerDB.stats or { hk = 0, quests = 0 }
end

-- =========================
-- Pick Active Hub
-- =========================
local function PickActiveHub()
    if not IsInGuild() then return nil end

    local numTotal = GetNumGuildMembers()
    for _, hubName in ipairs(LOL_GuildDB.hubs) do
        for i = 1, numTotal do
            local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
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
    if not LOL_PlayerDB.stats then
        InitPlayer()
    end
    local hk = LOL_PlayerDB.stats.hk + (LOL_PlayerDB.legacy and LOL_PlayerDB.legacy.hk or 0)
    local quests = LOL_PlayerDB.stats.quests + (LOL_PlayerDB.legacy and LOL_PlayerDB.legacy.quests or 0)
    local timestamp = time()
    local msg = hk .. "," .. quests .. "," .. timestamp

    local activeHub = PickActiveHub()
    if activeHub == playerName then
        LOL_GuildDB.players[playerName] = { hk = hk, quests = quests, timestamp = timestamp }
    elseif activeHub then
        SendAddonMessage("LOL", msg, "WHISPER", activeHub)
    else
        -- No hub online, stats saved locally until a hub comes online
    end
end

local function ReceiveStats(sender, msg)
    if not sender or not msg then return end
    -- Manual string splitting for Classic 1.12 (strsplit doesn't exist)
    local parts = {}
    local count = 0
    for part in string.gmatch(msg, "([^,]+)") do
        count = count + 1
        parts[count] = part
    end
    if count < 3 then return end -- Invalid message format
    local hk = tonumber(parts[1])
    local quests = tonumber(parts[2])
    local ts = tonumber(parts[3])
    if not hk or not quests or not ts then return end -- Invalid numbers

    local existing = LOL_GuildDB.players[sender]
    if not existing or ts > (existing.timestamp or 0) then
        LOL_GuildDB.players[sender] = {
            hk = hk,
            quests = quests,
            timestamp = ts
        }
    end
end

-- =========================
-- Genesis UI
-- =========================
local function ShowGenesisUI()
    if LOL_PlayerDB.genesisLocked then return end
    if LOL_GenesisFrame then return end -- Prevent creating multiple frames

    local frame = CreateFrame("Frame", "LOL_GenesisFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(250, 140)
    frame:SetPoint("CENTER")
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Enter Legacy Stats")

    local hkBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    hkBox:SetSize(100, 25)
    hkBox:SetPoint("TOP", frame, "TOP", 0, -40)
    hkBox:SetAutoFocus(false)
    hkBox:SetText("0")
    -- SetNumeric doesn't exist in Classic 1.12, validate on input
    hkBox:SetScript("OnChar", function(self, char)
        local text = self:GetText()
        if not tonumber(text) then
            -- Remove the last character if it makes the text non-numeric
            self:SetText(text:sub(1, -2))
        end
    end)
    local hkLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hkLabel:SetPoint("BOTTOM", hkBox, "TOP", 0, 0)
    hkLabel:SetText("Honorable Kills:")

    local questBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    questBox:SetSize(100, 25)
    questBox:SetPoint("TOP", hkBox, "BOTTOM", 0, -40)
    questBox:SetAutoFocus(false)
    questBox:SetText("0")
    -- SetNumeric doesn't exist in Classic 1.12, validate on input
    questBox:SetScript("OnChar", function(self, char)
        local text = self:GetText()
        if not tonumber(text) then
            -- Remove the last character if it makes the text non-numeric
            self:SetText(text:sub(1, -2))
        end
    end)
    local questLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    questLabel:SetPoint("BOTTOM", questBox, "TOP", 0, 0)
    questLabel:SetText("Quests Completed:")

    local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    btn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    btn:SetSize(120, 25)
    btn:SetText("Save Legacy Stats")
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")
    btn:SetScript("OnClick", function()
        LOL_PlayerDB.legacy = {
            hk = tonumber(hkBox:GetText()) or 0,
            quests = tonumber(questBox:GetText()) or 0
        }
        LOL_PlayerDB.genesisLocked = true
        frame:Hide()
        print("|cff00ff00[LOL]|r Legacy stats saved and locked!")
        SendStats()
    end)
end

-- =========================
-- Leaderboard UI
-- =========================
local LOL_UI = CreateFrame("Frame", "LOL_LeaderboardFrame", UIParent, "BasicFrameTemplateWithInset")
LOL_UI:SetSize(350, 400)
LOL_UI:SetPoint("CENTER")
LOL_UI:Hide()

LOL_UI.title = LOL_UI:CreateFontString(nil, "OVERLAY")
LOL_UI.title:SetFontObject("GameFontHighlight")
LOL_UI.title:SetPoint("LEFT", LOL_UI.TitleBg, "LEFT", 5, 0)
LOL_UI.title:SetText("Level One Lunatics Stats")

LOL_UI.scrollFrame = CreateFrame("ScrollFrame", nil, LOL_UI, "UIPanelScrollFrameTemplate")
LOL_UI.scrollFrame:SetPoint("TOPLEFT", LOL_UI, "TOPLEFT", 10, -30)
LOL_UI.scrollFrame:SetPoint("BOTTOMRIGHT", LOL_UI, "BOTTOMRIGHT", -30, 10)

LOL_UI.content = CreateFrame("Frame")
LOL_UI.content:SetSize(300, 1)
LOL_UI.scrollFrame:SetScrollChild(LOL_UI.content)

function LOL_UI:Update()
    for _, child in pairs(self.content.children or {}) do
        child:Hide()
    end
    self.content.children = {}

    local y = -5
    for name, stats in pairs(LOL_GuildDB.players) do
        local btn = CreateFrame("Button", nil, self.content)
        btn:SetSize(280, 20)
        btn:SetPoint("TOPLEFT", 5, y)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetText(string.format("%s | HK: %d | Quests: %d", name, stats.hk, stats.quests))

        btn:SetScript("OnClick", function()
            local info = string.format(
                "Player: %s\nHonorable Kills: %d\nQuests Completed: %d", 
                name, stats.hk, stats.quests
            )
            print("|cff00ff00[LOL]|r " .. info)
        end)

        btn:Show()
        table.insert(self.content.children, btn)
        y = y - 25
    end
    self.content:SetHeight(-y + 5)
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
    LOL_GuildDB  = { players = {}, hubs = { "Solutions", "AltHub1", "AltHub2" } }
    print("|cff00ff00[LOL]|r Player and guild stats have been reset!")
end

-- =========================
-- Event Frame
-- =========================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("QUEST_TURNED_IN")
f:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        InitPlayer()
        ShowGenesisUI()
        print("|cff00ff00[LOL]|r Guild stats tracking active! Hubs: " .. table.concat(LOL_GuildDB.hubs, ", "))

    elseif event == "QUEST_TURNED_IN" then
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.quests = LOL_PlayerDB.stats.quests + 1
        SendStats()

    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        -- In Classic 1.12, honor gain messages indicate HKs
        -- Format: "You gain X honor points" or similar
        -- This event fires when the player gets honor from a kill
        if not LOL_PlayerDB.stats then InitPlayer() end
        LOL_PlayerDB.stats.hk = LOL_PlayerDB.stats.hk + 1
        SendStats()

    elseif event == "CHAT_MSG_ADDON" then
        local args = {...}
        local prefix = args[1]
        local msg    = args[2]
        local channel= args[3]
        local sender = args[4]
    
        if prefix == "LOL" and msg and sender then
            local nameOnly = sender:match("^([^%-]+)") or sender
            ReceiveStats(nameOnly, msg)
        end
    

    elseif event == "PLAYER_LOGOUT" then
        SendStats()
    end
end)
