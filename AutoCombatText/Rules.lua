AutoCombatText = AutoCombatText or {}

function AutoCombatText:GetDefaultSettings()
    return self.db.default or self.DEFAULT_DB.default
end

function AutoCombatText:GetRules()
    return self.db.rules or {}
end

function AutoCombatText:FindRuleIndex(role, content, excludeIndex)
    for index, rule in ipairs(self:GetRules()) do
        if index ~= excludeIndex and rule.role == role and rule.content == content then
            return index
        end
    end
    return nil
end

function AutoCombatText:FindRuleIndexByRule(rule)
    for index, entry in ipairs(self:GetRules()) do
        if entry == rule then
            return index
        end
    end
    return nil
end

function AutoCombatText:WouldDuplicateRule(role, content, excludeRule)
    local excludeIndex = excludeRule and self:FindRuleIndexByRule(excludeRule) or nil
    return self:FindRuleIndex(role, content, excludeIndex) ~= nil
end

function AutoCombatText:TrySetRuleMatch(rule, role, content)
    if self:WouldDuplicateRule(role, content, rule) then
        self:PrintError(string.format(
            "A rule for %s + %s already exists.",
            self:FormatRole(role),
            self:FormatContent(content)
        ))
        return false
    end

    rule.role = role
    rule.content = content
    return true
end

function AutoCombatText:RuleMatches(rule, context)
    if not rule or not rule.enabled then
        return false
    end

    local roleMatches = rule.role == context.role or rule.role == "ANY"
    local contentMatches = rule.content == context.content
        or rule.content == "ANY"
        or (rule.content == "DUNGEON" and self:IsDungeonContent(context.content))
        or (rule.content == "RAID" and self:IsRaidContent(context.content))
    return roleMatches and contentMatches
end

function AutoCombatText:ScoreRule(rule, context)
    if not self:RuleMatches(rule, context) then
        return 0
    end

    local score = 0
    if rule.role == context.role then
        score = score + 2
    end
    if rule.content == context.content then
        score = score + 2
    end
    return score
end

function AutoCombatText:FindBestRule(context)
    local bestRule
    local bestScore = 0

    for _, rule in ipairs(self:GetRules()) do
        local score = self:ScoreRule(rule, context)
        if score > bestScore then
            bestScore = score
            bestRule = rule
        end
    end

    return bestRule, bestScore
end

function AutoCombatText:CreateDefaultRule()
    return {
        enabled = true,
        role = "ANY",
        content = "ANY",
        damage = "SHOW",
        healing = "SHOW",
    }
end

function AutoCombatText:AddRule(rule)
    rule = rule or self:CreateDefaultRule()
    if self:WouldDuplicateRule(rule.role, rule.content) then
        self:PrintError(string.format(
            "A rule for %s + %s already exists.",
            self:FormatRole(rule.role),
            self:FormatContent(rule.content)
        ))
        return nil
    end

    self.db.rules = self.db.rules or {}
    self.db.rules[#self.db.rules + 1] = self:DeepCopy(rule)
    return self.db.rules[#self.db.rules]
end

function AutoCombatText:RemoveRule(index)
    if not self.db.rules or not self.db.rules[index] then
        return false
    end
    table.remove(self.db.rules, index)
    return true
end

function AutoCombatText:GetSettingsForContext(context)
    local bestRule = self:FindBestRule(context)

    if bestRule then
        return {
            damage = bestRule.damage,
            healing = bestRule.healing,
            source = "Rule: " .. self:BuildRuleSourceLabel(bestRule.role, bestRule.content),
            rule = bestRule,
        }
    end

    local defaults = self:GetDefaultSettings()
    return {
        damage = defaults.damage,
        healing = defaults.healing,
        source = "Default settings",
        rule = nil,
    }
end
