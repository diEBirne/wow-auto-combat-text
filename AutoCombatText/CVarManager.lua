AutoCombatText = AutoCombatText or {}

-- Base Blizzard FCT CVars. Recent Retail builds use *_v2 names; resolved at runtime.
AutoCombatText.ManagedCVars = {
    damage = "floatingCombatTextCombatDamage",
    healing = "floatingCombatTextCombatHealing",
}

function AutoCombatText:ResolveCVarName(baseName)
    local v2Name = baseName .. "_v2"
    if GetCVar(v2Name) ~= nil then
        return v2Name
    end
    return baseName
end

function AutoCombatText:GetManagedCVarNames()
    local names = {}
    for _, baseName in pairs(self.ManagedCVars) do
        names[#names + 1] = self:ResolveCVarName(baseName)
    end
    table.sort(names)
    return names
end

function AutoCombatText:CaptureOriginalCVar(name)
    self.db.originalCVars = self.db.originalCVars or {}
    if self.db.originalCVars[name] == nil then
        self.db.originalCVars[name] = GetCVar(name)
    end
end

function AutoCombatText:CaptureAllOriginalCVars()
    for _, cvarName in ipairs(self:GetManagedCVarNames()) do
        self:CaptureOriginalCVar(cvarName)
    end
end

function AutoCombatText:ApplyActionToCVar(cvarName, action)
    if action == "IGNORE" then
        return
    end

    if GetCVar(cvarName) == nil then
        return
    end

    self:CaptureOriginalCVar(cvarName)

    if action == "SHOW" then
        SetCVar(cvarName, "1")
    elseif action == "HIDE" then
        SetCVar(cvarName, "0")
    end
end

function AutoCombatText:ApplyCategoryAction(category, action)
    local baseName = self.ManagedCVars[category]
    if not baseName then
        return
    end

    self:ApplyActionToCVar(self:ResolveCVarName(baseName), action)
end

function AutoCombatText:ApplyCombatTextSettings(settings)
    if not settings then
        return
    end

    self:ApplyCategoryAction("damage", settings.damage)
    self:ApplyCategoryAction("healing", settings.healing)
end

function AutoCombatText:RestoreOriginalCVars()
    self.db.originalCVars = self.db.originalCVars or {}

    for name, originalValue in pairs(self.db.originalCVars) do
        if originalValue ~= nil and GetCVar(name) ~= nil then
            SetCVar(name, originalValue)
        end
    end
end

function AutoCombatText:GetManagedCVarStatus()
    local status = {}
    for category, baseName in pairs(self.ManagedCVars) do
        local resolvedName = self:ResolveCVarName(baseName)
        status[resolvedName] = GetCVar(resolvedName)
        status[category] = status[resolvedName]
    end
    return status
end
