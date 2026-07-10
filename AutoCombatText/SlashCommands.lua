AutoCombatText = AutoCombatText or {}

local function HandleSlashCommand(self, input)
    local words = self:SplitWords(input)
    local command = self:ToLower(words[1] or "")

    if command == "" or command == "help" then
        self:PrintHelp()
        return
    end

    if command == "status" then
        self:PrintStatus()
        return
    end

    if command == "enable" then
        self:Enable()
        self:Print("Enabled.")
        return
    end

    if command == "disable" then
        self:Disable()
        self:Print("Disabled.")
        return
    end

    if command == "apply" then
        if self.db.enabled then
            self:ApplyCurrentContext(true)
            self:Print("Applied current context.")
        else
            self:Print("Addon is disabled. Use /act enable first.")
        end
        return
    end

    if command == "config" or command == "options" then
        self:OpenOptions()
        return
    end

    if command == "reset" then
        if self:ToLower(words[2] or "") == "confirm" then
            self:ResetProfileToDefaults()
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
            self:Print("Active profile reset to defaults.")
        else
            self:Print("This will reset the active profile to defaults.")
            self:Print("Type |cffffffff/act reset confirm|r to continue.")
        end
        return
    end

    self:PrintError("Unknown command. Type /act help for available commands.")
end

function AutoCombatText:PrintHelp()
    self:Print("Available commands:")
    self:Print("  /act help - Show this help")
    self:Print("  /act status - Show current context and settings")
    self:Print("  /act enable - Enable the addon")
    self:Print("  /act disable - Disable and optionally restore CVars")
    self:Print("  /act apply - Re-detect context and apply settings")
    self:Print("  /act config - Open addon options")
    self:Print("  /act reset confirm - Reset active profile to defaults")
end

function AutoCombatText:PrintStatus()
    local context = self:GetCurrentContext()
    local settings = self:GetSettingsForContext(context)
    local _, profileName = self:GetActiveProfile()

    self:Print(string.format("Auto Combat Text v%s", self.VERSION))
    self:Print(string.format("Enabled: %s", self.db.enabled and "yes" or "no"))
    self:Print(string.format("Current Role: %s", context.role))
    self:Print(string.format("Current Content: %s", context.content))
    self:Print(string.format("Active Profile: %s", profileName))
    self:Print(string.format("Resolved Source: %s", settings.source))
    self:Print(string.format("Damage Action: %s", settings.damage))
    self:Print(string.format("Healing Action: %s", settings.healing))

    self:Print(string.format("Current Role (display): %s", self:FormatRole(context.role)))
    self:Print(string.format("Current Content (display): %s", self:FormatContent(context.content)))
    self:Print(string.format("Damage Text: %s", self:FormatAction(settings.damage)))
    self:Print(string.format("Healing Text: %s", self:FormatAction(settings.healing)))

    for category, baseName in pairs(self.ManagedCVars) do
        local resolvedName = self:ResolveCVarName(baseName)
        local value = GetCVar(resolvedName)
        self:Print(string.format("%s (%s): %s", resolvedName, category, self:FormatCVarEnabled(value)))
    end
end

SLASH_AUTOCOMBATTEXT1 = "/act"
SLASH_AUTOCOMBATTEXT2 = "/autocombattext"
SlashCmdList["AUTOCOMBATTEXT"] = function(input)
    HandleSlashCommand(AutoCombatText, input)
end
