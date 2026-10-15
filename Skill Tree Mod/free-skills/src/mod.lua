--[[
  Free Skills & Upgrades v3.1.0

  Skills / SP / free upgrade recipes only touch safe fields.
  ALWAYS restores full vanilla dismantle values at the end (this mod loads last).
  seed=1 or low creep/nominator caused ~4 runes instead of ~120.
]]

local DEFAULT_CONFIG = {
    enabled = true,
    freeSkillNodeCosts = true,
    skillPointsPerLevel = 10,
    freeUpgradeRecipes = true,
    patchAllPresets = true,
}

local BOOL_KEYS = {
    enabled = true,
    freeSkillNodeCosts = true,
    freeUpgradeRecipes = true,
    patchAllPresets = true,
}

-- Vanilla ea_update_08 — required for full inventory dismantle rune yields.
local VANILLA_PRESETS = {
    { perkCostFactor = 0.5, perkUpgradeRecyclingFactor = 1.0 },
    { perkCostFactor = 1.0, perkUpgradeRecyclingFactor = 0.5 },
    { perkCostFactor = 1.0, perkUpgradeRecyclingFactor = 0.5 },
    { perkCostFactor = 1.25, perkUpgradeRecyclingFactor = 0.30000001192093 },
}

local VANILLA_BALANCING = {
    perkUpgradeCostSeed = 8,
    perkCostCreep = 0.15000000596046,
    advancedPerkCostNominator = 8.0,
    perkCostFactorWeaponsShield = 1.0,
    perkCostFactorArmor = 0.75,
    perkCostFactorRings = 0.5,
    trashStart = 5,
    trashEnd = 20,
}

local VANILLA_GEM = {
    extractBaseCost = 60,
    salvageGainPercentage = 0.5,
}

local function parseBool(value)
    value = string.lower(value)
    return value == "1" or value == "true" or value == "yes" or value == "on"
end

local function parseConfigFile(path)
    local values = {}
    local content = io.read_to_string(path)
    if not content then return values end

    for line in string.gmatch(content, "[^\r\n]+") do
        local trimmed = string.match(line, "^%s*(.-)%s*$")
        if trimmed ~= "" and not string.match(trimmed, "^#") then
            local key, rawValue = string.match(trimmed, "^([^=]+)=(.*)$")
            if key and rawValue then
                key = string.match(key, "^%s*(.-)%s*$")
                rawValue = string.match(rawValue, "^%s*(.-)%s*$")
                rawValue = string.match(rawValue, "^([^#%s]+)")
                if BOOL_KEYS[key] then
                    values[key] = parseBool(rawValue)
                else
                    local n = tonumber(rawValue)
                    if n ~= nil then values[key] = n end
                end
            end
        end
    end
    return values
end

local config = {}
for k, v in pairs(DEFAULT_CONFIG) do config[k] = v end
for k, v in pairs(parseConfigFile("config.txt")) do config[k] = v end

local function trySet(obj, field, value)
    pcall(function() obj[field] = value end)
end

local function zeroRecipeInput(input)
    if input.itemStack and input.itemStack.count then
        input.itemStack.count = 0
    end
    if input.inputItemCategory and input.inputItemCategory.count then
        input.inputItemCategory.count = 0
    end
end

local function applyVanillaDismantleRestore()
    local changed = 0

    for _, resource in ipairs(game.assets.get_resources_by_type("keen::BalancingTable")) do
        local b = resource.data
        for field, value in pairs(VANILLA_BALANCING) do
            if b[field] ~= value then
                b[field] = value
                changed = changed + 1
            end
        end
        if b.gemCrafting then
            for field, value in pairs(VANILLA_GEM) do
                if b.gemCrafting[field] ~= value then
                    b.gemCrafting[field] = value
                    changed = changed + 1
                end
            end
        end
    end

    for _, resource in ipairs(game.assets.get_resources_by_type("keen::GameSettingsPresetsResource")) do
        for i, preset in ipairs(resource.data.presets or {}) do
            local s = preset.settings
            local vanilla = VANILLA_PRESETS[i]
            if not s or not vanilla then goto next_preset end

            if s.enableDurability ~= true then
                s.enableDurability = true
                changed = changed + 1
            end
            if s.perkCostFactor ~= vanilla.perkCostFactor then
                s.perkCostFactor = vanilla.perkCostFactor
                changed = changed + 1
            end
            if s.perkUpgradeRecyclingFactor ~= vanilla.perkUpgradeRecyclingFactor then
                s.perkUpgradeRecyclingFactor = vanilla.perkUpgradeRecyclingFactor
                changed = changed + 1
            end

            ::next_preset::
        end
    end

    return changed
end

local function patchSkillTreeNodes()
    if not config.freeSkillNodeCosts then return 0 end

    local changed = 0
    for _, typeName in ipairs({ "keen::SkillTreeResource", "keen::DevSkillTreeResource" }) do
        for _, treeResource in ipairs(game.assets.get_resources_by_type(typeName)) do
            for _, node in ipairs(treeResource.data.nodes or {}) do
                if node.costs and node.costs > 0 then
                    node.costs = 0
                    changed = changed + 1
                end
            end
        end
    end
    return changed
end

local function patchBalancingTable()
    local resources = game.assets.get_resources_by_type("keen::BalancingTable")
    if #resources == 0 then return 0 end

    local changed = 0
    for _, resource in ipairs(resources) do
        local b = resource.data
        if config.skillPointsPerLevel and config.skillPointsPerLevel > 0 then
            b.skillPointsPerLevel = math.floor(config.skillPointsPerLevel)
            changed = changed + 1
        end
    end
    return changed
end

local function patchUpgradeRecipes()
    if not config.freeUpgradeRecipes then return 0 end

    local changed = 0
    for _, typeName in ipairs({ "keen::RecipeRegistryResource", "keen::DevRecipeRegistryResource" }) do
        for _, registryResource in ipairs(game.assets.get_resources_by_type(typeName)) do
            for _, recipe in ipairs(registryResource.data.recipes or {}) do
                if recipe.isUpgrade then
                    for _, input in ipairs(recipe.input or {}) do
                        zeroRecipeInput(input)
                    end
                    trySet(recipe, "requiredEnergy", 0)
                    trySet(recipe, "waterAmount", 0)
                    trySet(recipe, "waterCharges", 0)
                    changed = changed + 1
                end
            end
        end
    end
    return changed
end

local function verifySalvage()
    local presets = game.assets.get_resources_by_type("keen::GameSettingsPresetsResource")
    local balancing = game.assets.get_resources_by_type("keen::BalancingTable")
    if #presets == 0 or #balancing == 0 then return end

    local s = presets[1].data.presets[1].settings
    local b = balancing[1].data
    local g = b.gemCrafting

    print(string.format(
        "[free-skills] verify dur=%s cost=%s rec=%s seed=%s creep=%s perkW=%s gain=%s extract=%s",
        tostring(s and s.enableDurability),
        tostring(s and s.perkCostFactor),
        tostring(s and s.perkUpgradeRecyclingFactor),
        tostring(b.perkUpgradeCostSeed),
        tostring(b.perkCostCreep),
        tostring(b.perkCostFactorWeaponsShield),
        g and tostring(g.salvageGainPercentage) or "?",
        g and tostring(g.extractBaseCost) or "?"
    ))

    local ok = s and s.enableDurability == true
        and s.perkCostFactor == 0.5
        and b.perkUpgradeCostSeed == 8
        and b.perkCostFactorWeaponsShield == 1.0
        and g and g.extractBaseCost == 60
    if not ok then
        warn("[free-skills] Dismantle values not vanilla - run Restore-And-Patch.bat")
    end
end

print("[free-skills] v3.1.0 Loading...")

if config.enabled then
    local nodes = patchSkillTreeNodes()
    local balancing = patchBalancingTable()
    local upgrades = patchUpgradeRecipes()
    local restored = applyVanillaDismantleRestore()

    print(string.format(
        "[free-skills] nodes=%d spp=%d upgrades=%d dismantleRestore=%d",
        nodes, balancing, upgrades, restored
    ))
    verifySalvage()
else
    print("[free-skills] Disabled in config.txt")
end

print("[free-skills] Done.")
