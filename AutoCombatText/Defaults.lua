AutoCombatText = AutoCombatText or {}

local VERSION = "0.1.0"

AutoCombatText.VERSION = VERSION

AutoCombatText.DEFAULT_DB = {
    enabled = true,
    restoreOriginalOnDisable = true,

    activeProfile = "Default",

    profiles = {
        ["Default"] = {
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
                {
                    enabled = true,
                    role = "TANK",
                    content = "DELVE",
                    damage = "HIDE",
                    healing = "HIDE",
                },
                {
                    enabled = true,
                    role = "TANK",
                    content = "DUNGEON_MYTHIC",
                    damage = "HIDE",
                    healing = "HIDE",
                },
                {
                    enabled = true,
                    role = "TANK",
                    content = "DUNGEON_HEROIC",
                    damage = "SHOW",
                    healing = "SHOW",
                },
                {
                    enabled = true,
                    role = "TANK",
                    content = "DUNGEON_NORMAL",
                    damage = "SHOW",
                    healing = "SHOW",
                },
                {
                    enabled = true,
                    role = "TANK",
                    content = "GROUP",
                    damage = "SHOW",
                    healing = "SHOW",
                },
            },
        },
    },

    originalCVars = {},
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

function AutoCombatText:EnsureProfileRules(profile)
    profile.rules = profile.rules or {}

    local existingKeys = {}
    for _, rule in ipairs(profile.rules) do
        existingKeys[(rule.role or "ANY") .. ":" .. (rule.content or "ANY")] = true
    end

    local defaultRules = self.DEFAULT_DB.profiles["Default"].rules or {}
    for _, defaultRule in ipairs(defaultRules) do
        local key = defaultRule.role .. ":" .. defaultRule.content
        if not existingKeys[key] then
            profile.rules[#profile.rules + 1] = self:DeepCopy(defaultRule)
            existingKeys[key] = true
        end
    end
end

function AutoCombatText:InitializeDB()
    AutoCombatTextDB = AutoCombatTextDB or {}
    self.db = AutoCombatTextDB
    self:MergeDefaults(self.db, self.DEFAULT_DB)

    self.db.originalCVars = self.db.originalCVars or {}
    self.db.profiles = self.db.profiles or {}
    self.db.activeProfile = self.db.activeProfile or "Default"

    if not self.db.profiles[self.db.activeProfile] then
        self.db.activeProfile = "Default"
    end

    if not self.db.profiles["Default"] then
        self.db.profiles["Default"] = self:DeepCopy(self.DEFAULT_DB.profiles["Default"])
    else
        self:MergeDefaults(self.db.profiles["Default"], self.DEFAULT_DB.profiles["Default"])
    end

    for _, profile in pairs(self.db.profiles) do
        self:EnsureProfileRules(profile)
    end
end

function AutoCombatText:ResetProfileToDefaults(profileName)
    profileName = profileName or self.db.activeProfile
    self.db.profiles[profileName] = self:DeepCopy(self.DEFAULT_DB.profiles["Default"])
    if profileName ~= "Default" and self.DEFAULT_DB.profiles[profileName] then
        self:MergeDefaults(self.db.profiles[profileName], self.DEFAULT_DB.profiles[profileName])
    end
end
