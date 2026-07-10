AutoCombatText = AutoCombatText or {}

function AutoCombatText:IsMythicPlusActive()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return C_ChallengeMode.IsChallengeModeActive()
    end
    return false
end

function AutoCombatText:IsDelveActive()
    if C_PartyInfo and C_PartyInfo.IsDelveInProgress then
        return C_PartyInfo.IsDelveInProgress()
    end
    return false
end

function AutoCombatText:IsInOpenWorldGroup()
    if IsInGroup and IsInGroup() then
        return true
    end
    if IsInRaid and IsInRaid() then
        return true
    end
    return false
end

function AutoCombatText:GetPartyDungeonContent()
    local _, _, difficultyID = GetInstanceInfo()

    if difficultyID == 2 then
        return "DUNGEON_HEROIC"
    end
    if difficultyID == 23 then
        return "DUNGEON_MYTHIC"
    end
    return "DUNGEON_NORMAL"
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
    if self:IsDelveActive() then
        return "DELVE"
    end

    local inInstance, instanceType = IsInInstance()

    if not inInstance or instanceType == "none" then
        if self:IsInOpenWorldGroup() then
            return "GROUP"
        end
        return "OPEN_WORLD"
    end

    if instanceType == "party" then
        if self:IsMythicPlusActive() then
            return "MYTHIC_PLUS"
        end
        return self:GetPartyDungeonContent()
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
