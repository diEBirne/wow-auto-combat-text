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

function AutoCombatText:ApplyActionToCVar(cvarName, action)
    if action == "IGNORE" then
        return
    end

    local currentValue = GetCVar(cvarName)
    if currentValue == nil then
        return
    end

    local targetValue
    if action == "SHOW" then
        targetValue = "1"
    elseif action == "HIDE" then
        targetValue = "0"
    else
        return
    end

    if tostring(currentValue) == targetValue then
        return
    end

    SetCVar(cvarName, targetValue)
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

function AutoCombatText:GetManagedCVarStatus()
    local status = {}
    for category, baseName in pairs(self.ManagedCVars) do
        local resolvedName = self:ResolveCVarName(baseName)
        status[resolvedName] = GetCVar(resolvedName)
        status[category] = status[resolvedName]
    end
    return status
end
