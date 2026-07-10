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
end

function AutoCombatText:ResetProfileToDefaults(profileName)
    profileName = profileName or self.db.activeProfile
    self.db.profiles[profileName] = self:DeepCopy(self.DEFAULT_DB.profiles["Default"])
    if profileName ~= "Default" and self.DEFAULT_DB.profiles[profileName] then
        self:MergeDefaults(self.db.profiles[profileName], self.DEFAULT_DB.profiles[profileName])
    end
end
