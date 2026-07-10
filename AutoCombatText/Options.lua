AutoCombatText = AutoCombatText or {}

local ACTIONS = { "SHOW", "HIDE", "IGNORE" }

local PANEL_WIDTH = 560
local RULE_ROW_HEIGHT = 30
local RULES_TO_CONTEXT_GAP = 24

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
    return line, yOffset - 12
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

function AutoCombatText:CreateEnumDropdown(parent, x, yOffset, width, values, formatValue, getValue, setValue)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x, yOffset)

    local function RefreshText()
        UIDropDownMenu_SetWidth(dropdown, width)
        UIDropDownMenu_SetText(dropdown, formatValue(getValue()))
    end

    UIDropDownMenu_Initialize(dropdown, function()
        for _, value in ipairs(values) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = formatValue(value)
            info.arg1 = value
            info.func = function(_, selectedValue)
                setValue(selectedValue)
                RefreshText()
                if self.db.enabled then
                    self:ApplyCurrentContext(true)
                end
                self:RefreshOptionsPanel()
            end
            info.checked = (getValue() == value)
            UIDropDownMenu_AddButton(info)
        end
    end)

    dropdown.Refresh = RefreshText
    RefreshText()
    return dropdown
end

function AutoCombatText:CreateRoleDropdown(parent, x, yOffset, width, getValue, setValue)
    return self:CreateEnumDropdown(
        parent,
        x,
        yOffset,
        width,
        self.ROLES,
        function(value)
            return self:FormatRole(value)
        end,
        getValue,
        setValue
    )
end

function AutoCombatText:CreateContentDropdown(parent, x, yOffset, width, getValue, setValue)
    return self:CreateEnumDropdown(
        parent,
        x,
        yOffset,
        width,
        self.CONTENT_TYPES,
        function(value)
            return self:FormatContent(value)
        end,
        getValue,
        setValue
    )
end

function AutoCombatText:LayoutContextSection(contextStartY)
    local widgets = self.optionsWidgets
    if not widgets or not widgets.content then
        return contextStartY
    end

    local yOffset = contextStartY

    widgets.rulesSeparator:ClearAllPoints()
    widgets.rulesSeparator:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    widgets.rulesSeparator:SetPoint("RIGHT", widgets.content, "RIGHT", 0, 0)
    yOffset = yOffset - 12

    widgets.contextHeader:ClearAllPoints()
    widgets.contextHeader:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 28

    widgets.contextRole:ClearAllPoints()
    widgets.contextRole:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 18

    widgets.contextContent:ClearAllPoints()
    widgets.contextContent:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 18

    widgets.contextSource:ClearAllPoints()
    widgets.contextSource:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 18

    widgets.contextDamage:ClearAllPoints()
    widgets.contextDamage:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 18

    widgets.contextHealing:ClearAllPoints()
    widgets.contextHealing:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 18

    widgets.contextCVars:ClearAllPoints()
    widgets.contextCVars:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - 40

    widgets.applyButton:ClearAllPoints()
    widgets.applyButton:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)

    widgets.resetButton:ClearAllPoints()
    widgets.resetButton:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 120, yOffset)

    return yOffset - 30
end

function AutoCombatText:RebuildRuleRows()
    local widgets = self.optionsWidgets
    if not widgets or not widgets.content then
        return
    end

    for _, row in ipairs(widgets.ruleRows or {}) do
        row.enabledCheckbox:Hide()
        row.roleDropdown:Hide()
        row.contentDropdown:Hide()
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

        local roleDropdown = self:CreateRoleDropdown(
            widgets.content,
            24,
            rowY + 4,
            70,
            function()
                return rule.role
            end,
            function(value)
                rule.role = value
            end
        )

        local contentDropdown = self:CreateContentDropdown(
            widgets.content,
            100,
            rowY + 4,
            120,
            function()
                return rule.content
            end,
            function(value)
                rule.content = value
            end
        )

        local damageDropdown = self:CreateActionDropdown(
            widgets.content,
            250,
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
            370,
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
            roleDropdown = roleDropdown,
            contentDropdown = contentDropdown,
            damageDropdown = damageDropdown,
            healingDropdown = healingDropdown,
            rule = rule,
        }
    end

    local rulesBottomY = widgets.rulesFirstRowY - (#rules * RULE_ROW_HEIGHT)
    local contextStartY = rulesBottomY - RULES_TO_CONTEXT_GAP
    local bottomY = self:LayoutContextSection(contextStartY)
    widgets.content:SetHeight(math.abs(bottomY) + 24)
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
        row.roleDropdown.Refresh()
        row.contentDropdown.Refresh()
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
    content:SetSize(PANEL_WIDTH, 520)
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

    _, yOffset = CreateSeparator(content, yOffset)

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

    _, yOffset = CreateSeparator(content, yOffset)

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
    CreateLabel(content, "Content", 100, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, "Damage", 270, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, "Healing", 390, rulesStartY, "GameFontNormalSmall")

    local rulesFirstRowY = rulesStartY - 18

    local rulesSeparator = content:CreateTexture(nil, "ARTWORK")
    rulesSeparator:SetColorTexture(0.45, 0.45, 0.45, 0.55)
    rulesSeparator:SetHeight(1)

    local contextHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    contextHeader:SetText("Current Context")

    local contextRole = CreateLabel(content, "Role:", 0, 0, "GameFontHighlight")
    local contextContent = CreateLabel(content, "Content:", 0, 0, "GameFontHighlight")
    local contextSource = CreateLabel(content, "Active rule:", 0, 0, "GameFontHighlight")
    local contextDamage = CreateLabel(content, "Damage:", 0, 0, "GameFontHighlight")
    local contextHealing = CreateLabel(content, "Healing:", 0, 0, "GameFontHighlight")
    local contextCVars = CreateLabel(content, "", 0, 0, "GameFontHighlightSmall")
    contextCVars:SetJustifyH("LEFT")
    contextCVars:SetWidth(PANEL_WIDTH - 20)

    local applyButton = CreateButton(content, "Apply Now", 110, 0, 0, function()
        if self.db.enabled then
            self:ApplyCurrentContext(true)
        end
        self:RefreshOptionsPanel()
    end)

    local resetButton = CreateButton(content, "Reset Profile", 110, 120, 0, function()
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
        rulesSeparator = rulesSeparator,
        contextHeader = contextHeader,
        contextRole = contextRole,
        contextContent = contextContent,
        contextSource = contextSource,
        contextDamage = contextDamage,
        contextHealing = contextHealing,
        contextCVars = contextCVars,
        applyButton = applyButton,
        resetButton = resetButton,
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
