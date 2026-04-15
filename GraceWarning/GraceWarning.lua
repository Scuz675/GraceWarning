-- GraceWarning.lua
-- Vanilla / 1.12 compatible

local FRAME = CreateFrame("Frame", "GraceWarningFrame")
local TRIGGER_TEXT = "There is a grace period of 10 minutes"

local GW_Triggered = false
local GW_CountdownFrame = nil
local GW_EndTime = nil

local function GW_FormatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local mins = floor(seconds / 60)
    local secs = mod(seconds, 60)
    if secs < 10 then secs = "0" .. secs end
    return mins .. ":" .. secs
end

local function GW_StopCountdown()
    if GW_CountdownFrame then
        GW_CountdownFrame:Hide()
        GW_CountdownFrame:SetScript("OnUpdate", nil)
    end
    GW_EndTime = nil
end

local function GW_StartCountdown(duration)
    if not GW_CountdownFrame then
        local f = CreateFrame("Frame", "GraceWarningCountdownFrame", UIParent)
        f:SetWidth(260)
        f:SetHeight(90)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
        f:SetFrameStrata("DIALOG")

        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(f)
        f.bg:SetTexture(0, 0, 0, 0.75)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", f, "TOP", 0, -12)
        f.title:SetText("Loot Trade Grace")

        f.timer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.timer:SetPoint("CENTER", f, "CENTER", 0, -4)
        f.timer:SetText("10:00")

        f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.sub:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
        f.sub:SetText("Time remaining to trade loot")

        GW_CountdownFrame = f
    end

    GW_EndTime = GetTime() + duration
    GW_CountdownFrame:Show()
    GW_CountdownFrame.timer:SetText(GW_FormatTime(duration))

    GW_CountdownFrame:SetScript("OnUpdate", function()
        if not GW_EndTime then return end
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
    text = "WARNING\n\nThere is a 10 minute loot trade window.\n\nDo you want to stay or hearth?",
    button1 = "Stay",
    button2 = "Hearthstone",

    OnAccept = function() end,
    OnCancel = function() GraceWarning_UseHearthstone() end,

    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

FRAME:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        local msg = arg1
        if not GW_Triggered and msg and string.find(msg, TRIGGER_TEXT) then
            GW_Triggered = true
            PlaySound("RaidWarning")
            StaticPopup_Show("GRACE_WARNING_POPUP")
            GW_StartCountdown(600)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        GW_Triggered = false
        GW_StopCountdown()
    end
end)

FRAME:RegisterEvent("CHAT_MSG_SYSTEM")
FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
