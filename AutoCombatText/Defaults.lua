AutoCombatText = AutoCombatText or {}

local function GetAddOnVersion()
    if GetAddOnMetadata then
        local version = GetAddOnMetadata("AutoCombatText", "Version")
        if version and version ~= "" then
            return version
        end
    end
    return "0.2.0"
end

AutoCombatText.VERSION = GetAddOnVersion()

AutoCombatText.DEFAULT_DB = {
    enabled = true,

    default = {
        damage = "SHOW",
        healing = "SHOW",
    },

    rules = {
        {
            enabled = true,
            role = "TANK",
            content = "MYTHIC_PLUS",
            damage = "HIDE",
            healing = "HIDE",
        },
        {
            enabled = true,
            role = "TANK",
            content = "RAID",
            damage = "HIDE",
            healing = "HIDE",
        },
    },
}

local function isTable(value)
    return type(value) == "table"
end

function AutoCombatText:MergeDefaults(target, defaults)
    if not isTable(target) then
        return defaults
    end
    if not isTable(defaults) then
        return target
    end

    for key, defaultValue in pairs(defaults) do
        local currentValue = target[key]
        if currentValue == nil then
            if isTable(defaultValue) then
                target[key] = self:DeepCopy(defaultValue)
            else
                target[key] = defaultValue
            end
        elseif isTable(currentValue) and isTable(defaultValue) then
            self:MergeDefaults(currentValue, defaultValue)
        end
    end

    return target
end

function AutoCombatText:MigrateSavedData()
    if not self.db.profiles then
        return
    end

    local profile = self.db.profiles[self.db.activeProfile or "Default"]
        or self.db.profiles["Default"]

    if profile then
        if self.db.default == nil and profile.default then
            self.db.default = self:DeepCopy(profile.default)
        end
        if self.db.rules == nil and profile.rules then
            self.db.rules = self:DeepCopy(profile.rules)
        end
    end

    self.db.profiles = nil
    self.db.activeProfile = nil
end

function AutoCombatText:InitializeDB()
    AutoCombatTextDB = AutoCombatTextDB or {}
    self.db = AutoCombatTextDB
    self:MigrateSavedData()
    self:MergeDefaults(self.db, self.DEFAULT_DB)
    self.db.default = self.db.default or self:DeepCopy(self.DEFAULT_DB.default)
    self.db.rules = self.db.rules or {}
end

function AutoCombatText:ResetToDefaults()
    self.db.default = self:DeepCopy(self.DEFAULT_DB.default)
    self.db.rules = self:DeepCopy(self.DEFAULT_DB.rules)
end
