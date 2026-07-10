AutoCombatText = AutoCombatText or {}

local ACTIONS = { "SHOW", "HIDE", "IGNORE" }

local PANEL_WIDTH = 560
local RULE_ROW_HEIGHT = 30
local RULES_TO_CONTEXT_GAP = 24
local RULE_TOOLBAR_HEIGHT = 28
local CONTEXT_LINE_HEIGHT = 18
local CONTEXT_GROUP_GAP = 10
-- headerX aligns with dropdown label text; dropX is the UIDropDownMenuTemplate anchor.
local RULE_COLUMNS = {
    role = { header = "Role", headerX = 28, dropX = 12, width = 64 },
    content = { header = "Content", headerX = 138, dropX = 122, width = 102 },
    damage = { header = "Damage", headerX = 288, dropX = 272, width = 76 },
    healing = { header = "Healing", headerX = 408, dropX = 392, width = 72 },
}

local RULE_ON_X = 0
local RULE_REMOVE_X = 514

StaticPopupDialogs["AUTO_COMBAT_TEXT_RESET_SETTINGS"] = {
    text = "Reset all settings and rules to defaults?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        AutoCombatText:ResetToDefaults()
        if AutoCombatText.db.enabled then
            AutoCombatText:ApplyCurrentContext(true)
        end
        AutoCombatText:EnsureOptionsContent()
        AutoCombatText:RebuildRuleRows()
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

local function CreateRemoveButton(parent, x, rowY, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(22, 22)
    button:SetPoint("TOPLEFT", x, rowY + 1)
    button:SetText("-")

    local fontString = button:GetFontString()
    if fontString then
        fontString:ClearAllPoints()
        fontString:SetPoint("CENTER", button, "CENTER", 0, 0)
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    end

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Remove rule", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetFrameLevel(parent:GetFrameLevel() + 10)

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
    yOffset = yOffset - CONTEXT_LINE_HEIGHT

    widgets.contextContent:ClearAllPoints()
    widgets.contextContent:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - CONTEXT_LINE_HEIGHT - CONTEXT_GROUP_GAP

    widgets.contextSource:ClearAllPoints()
    widgets.contextSource:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - CONTEXT_LINE_HEIGHT

    widgets.contextDamage:ClearAllPoints()
    widgets.contextDamage:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - CONTEXT_LINE_HEIGHT

    widgets.contextHealing:ClearAllPoints()
    widgets.contextHealing:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)
    yOffset = yOffset - CONTEXT_LINE_HEIGHT - CONTEXT_GROUP_GAP

    widgets.applyButton:ClearAllPoints()
    widgets.applyButton:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, yOffset)

    widgets.resetButton:ClearAllPoints()
    widgets.resetButton:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 120, yOffset)

    return yOffset - 30
end

function AutoCombatText:LayoutRulesToolbar(toolbarY)
    local widgets = self.optionsWidgets
    if not widgets or not widgets.addRuleButton then
        return toolbarY
    end

    widgets.addRuleButton:ClearAllPoints()
    widgets.addRuleButton:SetPoint("TOPLEFT", widgets.content, "TOPLEFT", 0, toolbarY)

    return toolbarY - RULE_TOOLBAR_HEIGHT
end

function AutoCombatText:RemoveRuleRowByReference(rule)
    for index, profileRule in ipairs(self:GetRules()) do
        if profileRule == rule then
            self:RemoveRule(index)
            return true
        end
    end
    return false
end

function AutoCombatText:CreateRuleRow(widgets, rule)
    local row = { rule = rule }
    local content = widgets.content

    row.enabledCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    row.enabledCheckbox:SetSize(24, 24)
    row.enabledCheckbox:SetScript("OnClick", function(button)
        row.rule.enabled = button:GetChecked() and true or false
        if self.db.enabled then
            self:ApplyCurrentContext(true)
        end
        self:RefreshOptionsPanel()
    end)

    row.roleDropdown = self:CreateRoleDropdown(
        content,
        RULE_COLUMNS.role.dropX,
        0,
        RULE_COLUMNS.role.width,
        function()
            return row.rule.role
        end,
        function(value)
            if not self:TrySetRuleMatch(row.rule, value, row.rule.content) then
                row.roleDropdown.Refresh()
                return
            end
        end
    )

    row.contentDropdown = self:CreateContentDropdown(
        content,
        RULE_COLUMNS.content.dropX,
        0,
        RULE_COLUMNS.content.width,
        function()
            return row.rule.content
        end,
        function(value)
            if not self:TrySetRuleMatch(row.rule, row.rule.role, value) then
                row.contentDropdown.Refresh()
                return
            end
        end
    )

    row.damageDropdown = self:CreateActionDropdown(
        content,
        RULE_COLUMNS.damage.dropX,
        0,
        RULE_COLUMNS.damage.width,
        function()
            return row.rule.damage
        end,
        function(value)
            row.rule.damage = value
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
        end
    )

    row.healingDropdown = self:CreateActionDropdown(
        content,
        RULE_COLUMNS.healing.dropX,
        0,
        RULE_COLUMNS.healing.width,
        function()
            return row.rule.healing
        end,
        function(value)
            row.rule.healing = value
            if self.db.enabled then
                self:ApplyCurrentContext(true)
            end
        end
    )

    row.removeButton = CreateRemoveButton(content, RULE_REMOVE_X, 0, function()
        if self:RemoveRuleRowByReference(row.rule) and self.db.enabled then
            self:ApplyCurrentContext(true)
        end
        self:RebuildRuleRows()
        self:RefreshOptionsPanel()
    end)

    return row
end

function AutoCombatText:PositionRuleRow(row, rowY)
    row.enabledCheckbox:ClearAllPoints()
    row.enabledCheckbox:SetPoint("TOPLEFT", 0, rowY)
    row.enabledCheckbox:Show()

    row.roleDropdown:ClearAllPoints()
    row.roleDropdown:SetPoint("TOPLEFT", RULE_COLUMNS.role.dropX, rowY + 4)
    row.roleDropdown:Show()

    row.contentDropdown:ClearAllPoints()
    row.contentDropdown:SetPoint("TOPLEFT", RULE_COLUMNS.content.dropX, rowY + 4)
    row.contentDropdown:Show()

    row.damageDropdown:ClearAllPoints()
    row.damageDropdown:SetPoint("TOPLEFT", RULE_COLUMNS.damage.dropX, rowY + 4)
    row.damageDropdown:Show()

    row.healingDropdown:ClearAllPoints()
    row.healingDropdown:SetPoint("TOPLEFT", RULE_COLUMNS.healing.dropX, rowY + 4)
    row.healingDropdown:Show()

    row.removeButton:ClearAllPoints()
    row.removeButton:SetPoint("TOPLEFT", RULE_REMOVE_X, rowY + 1)
    row.removeButton:Show()
end

function AutoCombatText:HideRuleRow(row)
    if not row then
        return
    end

    row.enabledCheckbox:Hide()
    row.roleDropdown:Hide()
    row.contentDropdown:Hide()
    row.damageDropdown:Hide()
    row.healingDropdown:Hide()
    row.removeButton:Hide()
end

function AutoCombatText:RebuildRuleRows()
    local widgets = self.optionsWidgets
    if not widgets or not widgets.content then
        return
    end

    widgets.ruleRows = widgets.ruleRows or {}

    local rules = self:GetRules()
    local ruleCount = #rules

    for index, rule in ipairs(rules) do
        local row = widgets.ruleRows[index]
        if not row then
            row = self:CreateRuleRow(widgets, rule)
            widgets.ruleRows[index] = row
        else
            row.rule = rule
        end

        local rowY = widgets.rulesFirstRowY - ((index - 1) * RULE_ROW_HEIGHT)
        self:PositionRuleRow(row, rowY)
    end

    for index = ruleCount + 1, #widgets.ruleRows do
        self:HideRuleRow(widgets.ruleRows[index])
    end

    local rulesBottomY = widgets.rulesFirstRowY - (ruleCount * RULE_ROW_HEIGHT)
    local toolbarY = rulesBottomY - 6
    local contextStartY = self:LayoutRulesToolbar(toolbarY) - RULES_TO_CONTEXT_GAP
    local bottomY = self:LayoutContextSection(contextStartY)
    widgets.content:SetHeight(math.abs(bottomY) + 24)
end

function AutoCombatText:RefreshOptionsPanel()
    local widgets = self.optionsWidgets
    if not widgets then
        return
    end

    widgets.enabledCheckbox:SetChecked(self.db.enabled)

    widgets.defaultDamageDropdown.Refresh()
    widgets.defaultHealingDropdown.Refresh()

    for index, row in ipairs(widgets.ruleRows or {}) do
        if row.rule and row.enabledCheckbox:IsShown() then
            row.enabledCheckbox:SetChecked(row.rule.enabled)
            row.roleDropdown.Refresh()
            row.contentDropdown.Refresh()
            row.damageDropdown.Refresh()
            row.healingDropdown.Refresh()
        end
    end

    local context = self:GetCurrentContext()
    local settings = self:GetSettingsForContext(context)
    widgets.contextRole:SetText(string.format("Role: %s", self:FormatRole(context.role)))
    widgets.contextContent:SetText(string.format("Content: %s", self:FormatContent(context.content)))

    local appliedSource
    if settings.rule then
        appliedSource = self:BuildRuleSourceLabel(settings.rule.role, settings.rule.content)
    else
        appliedSource = "Default settings"
    end

    widgets.contextSource:SetText(string.format("Applied: %s", appliedSource))
    widgets.contextDamage:SetText(string.format("Damage: %s", self:FormatAction(settings.damage)))
    widgets.contextHealing:SetText(string.format("Healing: %s", self:FormatAction(settings.healing)))
end

function AutoCombatText:OpenOptions()
    self:RegisterOptionsPanel()
    self:EnsureOptionsContent()

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
        StaticPopup_Show("AUTO_COMBAT_TEXT_RESET_SETTINGS")
    end
    panel.refresh = function()
        self:EnsureOptionsContent()
        self:RebuildRuleRows()
        self:RefreshOptionsPanel()
    end

    panel:SetScript("OnShow", function()
        self:EnsureOptionsContent()
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

function AutoCombatText:EnsureOptionsContent()
    if self.optionsWidgets then
        return
    end

    local panel = self.optionsPanel
    if not panel then
        return
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

    _, yOffset = CreateSeparator(content, yOffset)

    local _, defaultsHeaderY = CreateSectionHeader(content, "Default Settings", yOffset)
    yOffset = defaultsHeaderY

    local defaultHint = CreateLabel(
        content,
        "Used when no matching rule applies.",
        0,
        yOffset,
        "GameFontDisableSmall"
    )
    defaultHint:SetWidth(PANEL_WIDTH - 20)
    defaultHint:SetJustifyH("LEFT")
    yOffset = yOffset - 22

    CreateLabel(content, "Damage Text:", 0, yOffset)
    local defaultDamageDropdown = self:CreateActionDropdown(
        content,
        120,
        yOffset + 8,
        120,
        function()
            return self:GetDefaultSettings().damage
        end,
        function(value)
            self.db.default.damage = value
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
            return self:GetDefaultSettings().healing
        end,
        function(value)
            self.db.default.healing = value
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
    CreateLabel(content, "On", RULE_ON_X, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, RULE_COLUMNS.role.header, RULE_COLUMNS.role.headerX, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, RULE_COLUMNS.content.header, RULE_COLUMNS.content.headerX, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, RULE_COLUMNS.damage.header, RULE_COLUMNS.damage.headerX, rulesStartY, "GameFontNormalSmall")
    CreateLabel(content, RULE_COLUMNS.healing.header, RULE_COLUMNS.healing.headerX, rulesStartY, "GameFontNormalSmall")

    local rulesFirstRowY = rulesStartY - 18

    local addRuleButton = CreateButton(content, "Add Rule", 100, 0, 0, function()
        if self:AddRule() then
            self:RebuildRuleRows()
            self:RefreshOptionsPanel()
        end
    end)

    local rulesSeparator = content:CreateTexture(nil, "ARTWORK")
    rulesSeparator:SetColorTexture(0.45, 0.45, 0.45, 0.55)
    rulesSeparator:SetHeight(1)

    local contextHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    contextHeader:SetText("Current Context")

    local contextRole = CreateLabel(content, "Role:", 0, 0, "GameFontHighlight")
    local contextContent = CreateLabel(content, "Content:", 0, 0, "GameFontHighlight")
    local contextSource = CreateLabel(content, "Applied:", 0, 0, "GameFontHighlight")
    local contextDamage = CreateLabel(content, "Damage:", 0, 0, "GameFontHighlight")
    local contextHealing = CreateLabel(content, "Healing:", 0, 0, "GameFontHighlight")

    local applyButton = CreateButton(content, "Apply Now", 110, 0, 0, function()
        if self.db.enabled then
            self:ApplyCurrentContext(true)
        end
        self:RefreshOptionsPanel()
    end)

    local resetButton = CreateButton(content, "Reset to Defaults", 130, 120, 0, function()
        StaticPopup_Show("AUTO_COMBAT_TEXT_RESET_SETTINGS")
    end)

    self.optionsWidgets = {
        content = content,
        enabledCheckbox = enabledCheckbox,
        defaultDamageDropdown = defaultDamageDropdown,
        defaultHealingDropdown = defaultHealingDropdown,
        rulesStartY = rulesStartY,
        rulesFirstRowY = rulesFirstRowY,
        ruleRows = {},
        addRuleButton = addRuleButton,
        rulesSeparator = rulesSeparator,
        contextHeader = contextHeader,
        contextRole = contextRole,
        contextContent = contextContent,
        contextSource = contextSource,
        contextDamage = contextDamage,
        contextHealing = contextHealing,
        applyButton = applyButton,
        resetButton = resetButton,
    }
end
