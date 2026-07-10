AutoCombatText = AutoCombatText or {}

function AutoCombatText:GetActiveProfile()
    local profileName = self.db.activeProfile or "Default"
    local profile = self.db.profiles[profileName]
    if not profile then
        profile = self.db.profiles["Default"]
    end
    return profile, profileName
end

function AutoCombatText:RuleMatches(rule, context)
    if not rule or not rule.enabled then
        return false
    end

    local roleMatches = rule.role == context.role or rule.role == "ANY"
    local contentMatches = rule.content == context.content
        or rule.content == "ANY"
        or (rule.content == "DUNGEON" and self:IsDungeonContent(context.content))
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

function AutoCombatText:FindBestRule(profile, context)
    local bestRule
    local bestScore = 0

    for _, rule in ipairs(profile.rules or {}) do
        local score = self:ScoreRule(rule, context)
        if score > bestScore then
            bestScore = score
            bestRule = rule
        end
    end

    return bestRule, bestScore
end

function AutoCombatText:GetSettingsForContext(context)
    local profile = self:GetActiveProfile()
    local bestRule = self:FindBestRule(profile, context)

    if bestRule then
        return {
            damage = bestRule.damage,
            healing = bestRule.healing,
            source = "Rule: " .. self:BuildRuleSourceLabel(bestRule.role, bestRule.content),
            rule = bestRule,
        }
    end

    local defaults = profile.default or self.DEFAULT_DB.profiles["Default"].default
    return {
        damage = defaults.damage,
        healing = defaults.healing,
        source = "Profile default",
        rule = nil,
    }
end
