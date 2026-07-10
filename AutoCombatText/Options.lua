AutoCombatText = AutoCombatText or {}

local ACTIONS = { "SHOW", "HIDE", "IGNORE" }

local PANEL_WIDTH = 560
local RULE_ROW_HEIGHT = 30
local BASE_CONTENT_HEIGHT = 430

StaticPopupDialogs["AUTO_COMBAT_TEXT_RESET_PROFILE"] = {
    text = "Reset the active profile to default settings?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        AutoCombatText:ResetProfileToDefaults()
        if AutoCombatText.db.enabled then
            AutoCombatText:ApplyCurrentContext(true)
        end
        AutoCombatText:RefreshOptionsPanel()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, yOffset)
    header:SetText(text)
    return header, yOffset - 28
end

local function CreateLabel(parent, text, x, yOffset, font)
    local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, yOffset)
    label:SetText(text)
    return label
end

local function CreateSeparator(parent, yOffset)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.45, 0.45, 0.45, 0.55)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 0, yOffset)
    line:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    return yOffset - 12
end

local function CreateCheckbox(parent, label, tooltip, yOffset, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 0, yOffset)
    checkbox.Text:SetText(label)
    checkbox.tooltipText = tooltip
    checkbox:SetScript("OnClick", onClick)
    return checkbox, yOffset - 30
end

local function CreateButton(parent, text, width, x, yOffset, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetPoint("TOPLEFT", x, yOffset)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

function AutoCombatText:CreateActionDropdown(parent, x, yOffset, width, getValue, setValue)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x, yOffset)

    local function RefreshText()
        UIDropDownMenu_SetWidth(dropdown, width)
        UIDropDownMenu_SetText(dropdown, self:FormatAction(getValue()))
    end

    UIDropDownMenu_Initialize(dropdown, function()
        for _, action in ipairs(ACTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = self:FormatAction(action)
            info.arg1 = action
            info.func = function(_, selectedAction)
                setValue(selectedAction)
                RefreshText()
            end
            info.checked = (getValue() == action)
            UIDropDownMenu_AddButton(info)
        end
    end)

    dropdown.Refresh = RefreshText
    RefreshText()
    return dropdown
end

function AutoCombatText:RebuildRuleRows()
    local widgets = self.optionsWidgets
    if not widgets or not widgets.content then
        return
    end

    for _, row in ipairs(widgets.ruleRows or {}) do
        row.enabledCheckbox:Hide()
        row.roleLabel:Hide()
        row.contentLabel:Hide()
        row.damageDropdown:Hide()
        row.healingDropdown:Hide()
    end
    widgets.ruleRows = {}

    local profile = self:GetActiveProfile()
    local rules = profile.rules or {}

    for index, rule in ipairs(rules) do
        local rowY = widgets.rulesFirstRowY - ((index - 1) * RULE_ROW_HEIGHT)

        local enabledCheckbox = CreateFrame("CheckButton", nil, widgets.content, "UICheckButtonTemplate")
        enabledCheckbox:SetSize(24, 24)
        enabledCheckbox:SetPoint("TOPLEFT", 0, rowY)
        enabledCheckbox:SetScript("OnClick", function(button)
            rule.enabled = button:GetChecked() and true or false
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
            self:RefreshOptionsPanel()
        end)

        local roleLabel = CreateLabel(widgets.content, self:FormatRole(rule.role), 28, rowY + 2, "GameFontHighlightSmall")
        local contentLabel = CreateLabel(widgets.content, self:FormatContent(rule.content), 90, rowY + 2, "GameFontHighlightSmall")

        local damageDropdown = self:CreateActionDropdown(
            widgets.content,
            200,
            rowY + 4,
            110,
            function()
                return rule.damage
            end,
            function(value)
                rule.damage = value
                if self.db.enabled then
                    self:ApplyCurrentContext(true)
                end
            end
        )

        local healingDropdown = self:CreateActionDropdown(
            widgets.content,
            320,
            rowY + 4,
            110,
            function()
                return rule.healing
            end,
            function(value)
                rule.healing = value
                if self.db.enabled then
                    self:ApplyCurrentContext(true)
                end
            end
        )

        widgets.ruleRows[index] = {
            enabledCheckbox = enabledCheckbox,
            roleLabel = roleLabel,
            contentLabel = contentLabel,
            damageDropdown = damageDropdown,
            healingDropdown = healingDropdown,
            rule = rule,
        }
    end

    local contentHeight = BASE_CONTENT_HEIGHT + (#rules * RULE_ROW_HEIGHT)
    widgets.content:SetHeight(contentHeight)
end

function AutoCombatText:RefreshOptionsPanel()
    local widgets = self.optionsWidgets
    if not widgets then
        return
    end

    widgets.enabledCheckbox:SetChecked(self.db.enabled)
    widgets.restoreCheckbox:SetChecked(self.db.restoreOriginalOnDisable)

    local profile, profileName = self:GetActiveProfile()
    widgets.profileLabel:SetText(string.format("Active profile: %s", profileName))

    widgets.defaultDamageDropdown.Refresh()
    widgets.defaultHealingDropdown.Refresh()

    for _, row in ipairs(widgets.ruleRows or {}) do
        row.enabledCheckbox:SetChecked(row.rule.enabled)
        row.damageDropdown.Refresh()
        row.healingDropdown.Refresh()
    end

    local context = self:GetCurrentContext()
    local settings = self:GetSettingsForContext(context)
    widgets.contextRole:SetText(string.format("Role: %s (%s)", self:FormatRole(context.role), context.role))
    widgets.contextContent:SetText(string.format("Content: %s (%s)", self:FormatContent(context.content), context.content))
    widgets.contextSource:SetText(string.format("Active rule: %s", settings.source))
    widgets.contextDamage:SetText(string.format("Damage: %s", self:FormatAction(settings.damage)))
    widgets.contextHealing:SetText(string.format("Healing: %s", self:FormatAction(settings.healing)))

    local cvarLines = {}
    for category, baseName in pairs(self.ManagedCVars) do
        local resolvedName = self:ResolveCVarName(baseName)
        local value = GetCVar(resolvedName)
        cvarLines[#cvarLines + 1] = string.format(
            "%s: %s",
            resolvedName,
            self:FormatCVarEnabled(value)
        )
    end
    table.sort(cvarLines)
    widgets.contextCVars:SetText(table.concat(cvarLines, "\n"))
end

function AutoCombatText:OpenOptions()
    if Settings and Settings.OpenToCategory and self.optionsCategoryID then
        Settings.OpenToCategory(self.optionsCategoryID)
        return
    end

    if self.optionsPanel and InterfaceOptionsFrame_OpenToCategory then
        if InterfaceOptionsFrame then
            InterfaceOptionsFrame:Show()
        end
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    end
end

function AutoCombatText:RegisterOptionsPanel()
    if self.optionsPanel then
        return
    end

    local panel = CreateFrame("Frame", "AutoCombatTextOptionsPanel")
    panel.name = "Auto Combat Text"
    panel.okay = function()
    end
    panel.cancel = function()
    end
    panel.default = function()
        StaticPopup_Show("AUTO_COMBAT_TEXT_RESET_PROFILE")
    end
    panel.refresh = function()
        self:RebuildRuleRows()
        self:RefreshOptionsPanel()
    end

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Auto Combat Text")

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    version:SetText(string.format("Version %s", self.VERSION))

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -56)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(PANEL_WIDTH, BASE_CONTENT_HEIGHT)
    scrollFrame:SetScrollChild(content)

    local yOffset = 0

    local enabledCheckbox
    enabledCheckbox, yOffset = CreateCheckbox(
        content,
        "Enable Auto Combat Text",
        "Automatically manage Blizzard Floating Combat Text based on role and content.",
        yOffset,
        function(button)
            if button:GetChecked() then
                self:Enable()
            else
                self:Disable()
            end
            self:RefreshOptionsPanel()
        end
    )

    local restoreCheckbox
    restoreCheckbox, yOffset = CreateCheckbox(
        content,
        "Restore original Blizzard settings when disabled",
        "When disabled, restore captured Blizzard FCT CVar values.",
        yOffset,
        function(button)
            self.db.restoreOriginalOnDisable = button:GetChecked() and true or false
        end
    )

    yOffset = CreateSeparator(content, yOffset)

    local _, defaultsHeaderY = CreateSectionHeader(content, "Profile Default", yOffset)
    yOffset = defaultsHeaderY

    local profileLabel = CreateLabel(content, "Active profile: Default", 0, yOffset, "GameFontHighlight")
    yOffset = yOffset - 24

    CreateLabel(content, "Damage Text:", 0, yOffset)
    local defaultDamageDropdown = self:CreateActionDropdown(
        content,
        120,
        yOffset + 8,
        120,
        function()
            return self:GetActiveProfile().default.damage
        end,
        function(value)
            local profile = self:GetActiveProfile()
            profile.default.damage = value
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
        end
    )
    yOffset = yOffset - 36

    CreateLabel(content, "Healing Text:", 0, yOffset)
    local defaultHealingDropdown = self:CreateActionDropdown(
        content,
        120,
        yOffset + 8,
        120,
        function()
            return self:GetActiveProfile().default.healing
        end,
        function(value)
            local profile = self:GetActiveProfile()
            profile.default.healing = value
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
        end
    )
    yOffset = yOffset - 40

    yOffset = CreateSeparator(content, yOffset)

    local _, rulesHeaderY = CreateSectionHeader(content, "Rules", yOffset)
    yOffset = rulesHeaderY

    CreateLabel(
        content,
        "Checked rules are active. Higher-specificity rules override broader ones.",
        0,
        yOffset,
        "GameFontDisableSmall"
    )
    yOffset = yOffset - 22

    local rulesStartY = yOffset
    CreateLabel(content, "On", 0, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, "Role", 28, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, "Content", 90, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, "Damage", 220, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, "Healing", 340, rulesStartY, "GameFontNormalSmall")

    local rulesFirstRowY = rulesStartY - 18
    yOffset = rulesFirstRowY - 20

    yOffset = CreateSeparator(content, yOffset)

    local _, contextHeaderY = CreateSectionHeader(content, "Current Context", yOffset)
    yOffset = contextHeaderY

    local contextRole = CreateLabel(content, "Role:", 0, yOffset, "GameFontHighlight")
    yOffset = yOffset - 18
    local contextContent = CreateLabel(content, "Content:", 0, yOffset, "GameFontHighlight")
    yOffset = yOffset - 18
    local contextSource = CreateLabel(content, "Active rule:", 0, yOffset, "GameFontHighlight")
    yOffset = yOffset - 18
    local contextDamage = CreateLabel(content, "Damage:", 0, yOffset, "GameFontHighlight")
    yOffset = yOffset - 18
    local contextHealing = CreateLabel(content, "Healing:", 0, yOffset, "GameFontHighlight")
    yOffset = yOffset - 18
    local contextCVars = CreateLabel(content, "", 0, yOffset, "GameFontHighlightSmall")
    contextCVars:SetJustifyH("LEFT")
    contextCVars:SetWidth(PANEL_WIDTH - 20)
    yOffset = yOffset - 40

    CreateButton(content, "Apply Now", 110, 0, yOffset, function()
        if self.db.enabled then
            self:ApplyCurrentContext(true)
        end
        self:RefreshOptionsPanel()
    end)

    CreateButton(content, "Reset Profile", 110, 120, yOffset, function()
        StaticPopup_Show("AUTO_COMBAT_TEXT_RESET_PROFILE")
    end)

    self.optionsWidgets = {
        content = content,
        enabledCheckbox = enabledCheckbox,
        restoreCheckbox = restoreCheckbox,
        profileLabel = profileLabel,
        defaultDamageDropdown = defaultDamageDropdown,
        defaultHealingDropdown = defaultHealingDropdown,
        rulesStartY = rulesStartY,
        rulesFirstRowY = rulesFirstRowY,
        ruleRows = {},
        contextRole = contextRole,
        contextContent = contextContent,
        contextSource = contextSource,
        contextDamage = contextDamage,
        contextHealing = contextHealing,
        contextCVars = contextCVars,
    }

    panel:SetScript("OnShow", function()
        self:RebuildRuleRows()
        self:RefreshOptionsPanel()
    end)

    self.optionsPanel = panel

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Auto Combat Text")
        Settings.RegisterAddOnCategory(category)
        self.optionsCategoryID = category.ID
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end
