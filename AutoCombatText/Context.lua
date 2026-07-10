AutoCombatText = AutoCombatText or {}

function AutoCombatText:IsMythicPlusActive()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return C_ChallengeMode.IsChallengeModeActive()
    end
    return false
end

function AutoCombatText:GetCurrentRole()
    local assignedRole = UnitGroupRolesAssigned("player")
    if assignedRole and assignedRole ~= "NONE" then
        return assignedRole
    end

    local specIndex = GetSpecialization()
    if specIndex then
        local role = GetSpecializationRole(specIndex)
        if role then
            return role
        end
    end

    return "NONE"
end

function AutoCombatText:GetCurrentContent()
    local inInstance, instanceType = IsInInstance()

    if not inInstance or instanceType == "none" then
        return "OPEN_WORLD"
    end

    if instanceType == "party" then
        if self:IsMythicPlusActive() then
            return "MYTHIC_PLUS"
        end
        return "DUNGEON"
    end

    if instanceType == "raid" then
        return "RAID"
    end

    if instanceType == "arena" or instanceType == "pvp" then
        return "PVP"
    end

    if instanceType == "scenario" then
        return "SCENARIO"
    end

    return "OTHER"
end

function AutoCombatText:GetCurrentContext()
    return {
        role = self:GetCurrentRole(),
        content = self:GetCurrentContent(),
    }
end

function AutoCombatText:BuildRuleSourceLabel(role, content)
    return string.format("%s + %s", self:FormatRole(role), self:FormatContent(content))
end
