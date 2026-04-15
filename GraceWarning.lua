-- GraceWarning.lua
-- Vanilla / 1.12 compatible

local FRAME = CreateFrame("Frame", "GraceWarningFrame")
local TRIGGER_TEXT = "There is a grace period of 10 minutes"

local GW_Triggered = false
local GW_CountdownFrame = nil
local GW_EndTime = nil

local function GW_FormatTime(seconds)
    if seconds < 0 then
        seconds = 0
    end

    local mins = floor(seconds / 60)
    local secs = mod(seconds, 60)

    if secs < 10 then
        secs = "0" .. secs
    end

    return mins .. ":" .. secs
end

local function GW_StopCountdown()
    if GW_CountdownFrame then
        GW_CountdownFrame:Hide()
        GW_CountdownFrame:SetScript("OnUpdate", nil)
    end
    GW_EndTime = nil
end

local function GW_CreateCountdownFrame()
    if GW_CountdownFrame then
        return
    end

    local f = CreateFrame("Frame", "GraceWarningCountdownFrame", UIParent)
    f:SetWidth(280)
    f:SetHeight(100)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(1)
    f:SetMovable(1)
    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function()
        this:StartMoving()
    end)

    f:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.bg:SetTexture(0, 0, 0, 0.80)

    local top = f:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetTexture(1, 0.82, 0, 1)

    local bottom = f:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    bottom:SetTexture(1, 0.82, 0, 1)

    local left = f:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    left:SetTexture(1, 0.82, 0, 1)

    local right = f:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    right:SetTexture(1, 0.82, 0, 1)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -12)
    f.title:SetText("Raid Save Warning")

    f.timer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.timer:SetPoint("CENTER", f, "CENTER", 0, -2)
    f.timer:SetText("10:00")

    f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.sub:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    f.sub:SetText("Drag to move")

    f.close = CreateFrame("Button", nil, f)
    f.close:SetWidth(20)
    f.close:SetHeight(20)
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    f.close.text = f.close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.close.text:SetAllPoints(f.close)
    f.close.text:SetText("X")

    f.close:SetScript("OnClick", function()
        GW_StopCountdown()
    end)

    GW_CountdownFrame = f
end

local function GW_StartCountdown(duration)
    GW_CreateCountdownFrame()

    GW_EndTime = GetTime() + duration
    GW_CountdownFrame:Show()
    GW_CountdownFrame.timer:SetText(GW_FormatTime(duration))

    GW_CountdownFrame:SetScript("OnUpdate", function()
        if not GW_EndTime then
            return
        end

        local remaining = floor(GW_EndTime - GetTime())

        if remaining <= 0 then
            GW_CountdownFrame.timer:SetText("0:00")
            GW_StopCountdown()
            return
        end

        GW_CountdownFrame.timer:SetText(GW_FormatTime(remaining))
    end)
end

function GraceWarning_UseHearthstone()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink and string.find(itemLink, "Hearthstone") then
                UseContainerItem(bag, slot)
                return
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GraceWarning: Hearthstone not found.|r")
end

StaticPopupDialogs["GRACE_WARNING_POPUP"] = {
    text = "WARNING\n\nYou have 10 minutes to leave this raid before being saved to it!",
    button1 = "Stay",
    button2 = "Hearthstone",

    OnAccept = function()
    end,

    OnCancel = function()
        GraceWarning_UseHearthstone()
    end,

    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

local function GraceWarning_Trigger()
    if GW_Triggered then
        return
    end

    GW_Triggered = true
    PlaySound("RaidWarning")
    StaticPopup_Show("GRACE_WARNING_POPUP")
    GW_StartCountdown(600)
end

local function GraceWarning_HandleMessage(msg)
    if msg and string.find(msg, TRIGGER_TEXT) then
        GraceWarning_Trigger()
    end
end

FRAME:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        GraceWarning_HandleMessage(arg1)
    elseif event == "PLAYER_ENTERING_WORLD" then
        GW_Triggered = false
        GW_StopCountdown()
    end
end)

FRAME:RegisterEvent("CHAT_MSG_SYSTEM")
FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")

function GraceWarning_Test()
    GW_Triggered = false
    GraceWarning_Trigger()
end

function GraceWarning_TestMessage()
    GW_Triggered = false
    GraceWarning_HandleMessage("There is a grace period of 10 minutes allowing you to trade raid loot to others in case it's wrongly assigned.")
end

function GraceWarning_TestCountdown(seconds)
    GW_StartCountdown(seconds or 10)
end

SLASH_GRACEWARNING1 = "/gw"
SlashCmdList["GRACEWARNING"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "test" then
        GraceWarning_Test()
    elseif msg == "testmsg" then
        GraceWarning_TestMessage()
    elseif msg == "timer" then
        GraceWarning_TestCountdown(10)
    elseif msg == "reset" then
        GW_Triggered = false
        GW_StopCountdown()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GraceWarning: reset.|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00GraceWarning commands: /gw test, /gw testmsg, /gw timer, /gw reset|r")
    end
end
