AutoCombatText = AutoCombatText or {}

local APPLY_DEBOUNCE_SECONDS = 0.15

local EVENTS = {
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "GROUP_ROSTER_UPDATE",
    "PLAYER_ROLES_ASSIGNED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "CHALLENGE_MODE_START",
    "CHALLENGE_MODE_COMPLETED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

function AutoCombatText:ContextsEqual(a, b)
    if not a or not b then
        return false
    end
    return a.role == b.role and a.content == b.content
end

function AutoCombatText:SettingsEqual(a, b)
    if not a or not b then
        return false
    end
    return a.damage == b.damage and a.healing == b.healing
end

function AutoCombatText:ApplyCurrentContext(force)
    if not self.db or not self.db.enabled then
        return
    end

    local context = self:GetCurrentContext()
    local settings = self:GetSettingsForContext(context)

    if not force
        and self.lastContext
        and self.lastAppliedSettings
        and self:ContextsEqual(self.lastContext, context)
        and self:SettingsEqual(self.lastAppliedSettings, settings)
    then
        return
    end

    self:ApplyCombatTextSettings(settings)
    self.lastContext = context
    self.lastAppliedSettings = settings

    if self.optionsPanel and self.optionsPanel:IsShown() then
        self:RefreshOptionsPanel()
    end
end

function AutoCombatText:ScheduleApply(force)
    if self.pendingApply then
        return
    end

    self.pendingApply = true
    C_Timer.After(APPLY_DEBOUNCE_SECONDS, function()
        self.pendingApply = false
        self:ApplyCurrentContext(force)
    end)
end

function AutoCombatText:OnEvent(event)
    if event == "PLAYER_LOGIN" then
        self:CaptureAllOriginalCVars()
        self:ApplyCurrentContext(true)
        return
    end

    self:ScheduleApply(false)
end

function AutoCombatText:RegisterEvents(frame)
    for _, eventName in ipairs(EVENTS) do
        local ok = pcall(frame.RegisterEvent, frame, eventName)
        if not ok and self.debug then
            self:Print("Could not register event: " .. eventName)
        end
    end
end

function AutoCombatText:Enable()
    self.db.enabled = true
    self:ApplyCurrentContext(true)
end

function AutoCombatText:Disable()
    self.db.enabled = false
    if self.db.restoreOriginalOnDisable then
        self:RestoreOriginalCVars()
    end
    self.lastContext = nil
    self.lastAppliedSettings = nil
end

function AutoCombatText:Initialize()
    self:InitializeDB()
    self:CaptureAllOriginalCVars()

    local frame = CreateFrame("Frame", "AutoCombatTextFrame")
    frame:SetScript("OnEvent", function(_, event)
        self:OnEvent(event)
    end)

    self:RegisterEvents(frame)
    self.frame = frame

    self:RegisterOptionsPanel()

    if IsLoggedIn and IsLoggedIn() then
        C_Timer.After(0, function()
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
        end)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event ~= "ADDON_LOADED" or addonName ~= "AutoCombatText" then
        return
    end

    AutoCombatText:Initialize()
    initFrame:UnregisterEvent("ADDON_LOADED")
end)
