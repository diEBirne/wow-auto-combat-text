AutoCombatText = AutoCombatText or {}

function AutoCombatText:DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, item in pairs(value) do
        copy[key] = self:DeepCopy(item)
    end
    return copy
end

function AutoCombatText:Trim(text)
    if not text then
        return ""
    end
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

function AutoCombatText:SplitWords(text)
    local words = {}
    for word in self:Trim(text):gmatch("%S+") do
        words[#words + 1] = word
    end
    return words
end

function AutoCombatText:ToLower(text)
    if not text then
        return ""
    end
    return string.lower(text)
end

function AutoCombatText:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffAuto Combat Text:|r " .. tostring(message))
end

function AutoCombatText:PrintError(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Auto Combat Text:|r " .. tostring(message))
end

function AutoCombatText:FormatAction(action)
    if action == "SHOW" then
        return "Show"
    elseif action == "HIDE" then
        return "Hide"
    elseif action == "IGNORE" then
        return "Ignore"
    end
    return tostring(action or "Unknown")
end

function AutoCombatText:FormatCVarEnabled(value)
    if value == "1" or value == 1 or value == true then
        return "Enabled"
    elseif value == "0" or value == 0 or value == false then
        return "Disabled"
    end
    return tostring(value or "Unknown")
end

function AutoCombatText:FormatRole(role)
    if role == "DAMAGER" then
        return "DPS"
    elseif role == "TANK" then
        return "Tank"
    elseif role == "HEALER" then
        return "Healer"
    elseif role == "ANY" then
        return "Any"
    elseif role == "NONE" then
        return "None"
    end
    return tostring(role or "Unknown")
end

function AutoCombatText:FormatContent(content)
    local labels = {
        ANY = "Any",
        OPEN_WORLD = "Open World",
        DUNGEON = "Dungeon",
        MYTHIC_PLUS = "Mythic+",
        RAID = "Raid",
        PVP = "PvP",
        SCENARIO = "Scenario",
        OTHER = "Other",
    }
    return labels[content] or tostring(content or "Unknown")
end

function AutoCombatText:NormalizeRoleInput(text)
    local value = self:ToLower(text)
    if value == "tank" then
        return "TANK"
    elseif value == "healer" then
        return "HEALER"
    elseif value == "dps" or value == "damager" or value == "damage" then
        return "DAMAGER"
    elseif value == "any" then
        return "ANY"
    elseif value == "none" then
        return "NONE"
    end
    return nil
end

function AutoCombatText:NormalizeContentInput(text)
    local value = self:ToLower(text)
    if value == "any" then
        return "ANY"
    elseif value == "openworld" or value == "open_world" or value == "world" then
        return "OPEN_WORLD"
    elseif value == "dungeon" then
        return "DUNGEON"
    elseif value == "mythicplus" or value == "mythic+" or value == "m+" then
        return "MYTHIC_PLUS"
    elseif value == "raid" then
        return "RAID"
    elseif value == "pvp" or value == "arena" or value == "battleground" then
        return "PVP"
    elseif value == "scenario" then
        return "SCENARIO"
    elseif value == "other" then
        return "OTHER"
    end
    return nil
end

function AutoCombatText:NormalizeActionInput(text)
    local value = self:ToLower(text)
    if value == "show" then
        return "SHOW"
    elseif value == "hide" then
        return "HIDE"
    elseif value == "ignore" then
        return "IGNORE"
    end
    return nil
end
