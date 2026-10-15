--[[
  Free Skills & Upgrades v3.2.0

  Skills / SP / free upgrade recipes only touch safe fields.

  The dismantle value restore (hardcoded ea_update_08 values) is now opt-in via
  restoreDismantleValues. EML always patches from the vanilla backup, so values
  changed by older versions of this mod cannot persist; forcing old values would
  overwrite the rebalanced values of newer game versions.
]]

local VERSION = "3.2.0"

local DEFAULT_CONFIG = {
    enabled = true,
    freeSkillNodeCosts = true,
    skillPointsPerLevel = 10,
    freeUpgradeRecipes = true,
    restoreDismantleValues = false,
}

local BOOL_KEYS = {
    enabled = true,
    freeSkillNodeCosts = true,
    freeUpgradeRecipes = true,
    restoreDismantleValues = true,
}

-- Vanilla ea_update_08 values, only used when restoreDismantleValues = true.
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

-- Errors raised by EML functions must be avoided entirely: in EML release
-- builds an error thrown from EML into Lua aborts the game process, even
-- inside pcall. So existence is checked up front instead of relying on pcall.

-- Returns true when the struct value has a field with this name, including
-- fields inherited from base types.
local function hasField(obj, field)
    local t = game.types.of(obj)
    while t do
        local fields = t.struct_fields
        if fields and fields[field] ~= nil then
            return true
        end
        t = t.inner_type
    end
    return false
end

-- Reads a field, or returns nil when the field does not exist (e.g. it was
-- renamed in a newer game version).
local function tryGet(obj, field)
    if obj ~= nil and hasField(obj, field) then
        return obj[field]
    end
    return nil
end

-- Writes a field if it exists, returns true on success.
local function trySet(obj, field, value)
    if obj ~= nil and hasField(obj, field) then
        obj[field] = value
        return true
    end
    return false
end

-- Returns all resources of a type, or an empty list when the type is unknown.
local function getResources(typeName)
    if game.types.get(typeName) == nil then
        warn(string.format("[free-skills] Resource type %s not found in this game version", typeName))
        return {}
    end
    return game.assets.get_resources_by_type(typeName)
end

local function zeroRecipeInput(input)
    for _, field in ipairs({ "itemStack", "inputItemCategory" }) do
        local stack = tryGet(input, field)
        if stack and tryGet(stack, "count") then
            trySet(stack, "count", 0)
        end
    end
end

local function applyVanillaDismantleRestore()
    local changed = 0

    for _, resource in ipairs(getResources("keen::BalancingTable")) do
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

    for _, resource in ipairs(getResources("keen::GameSettingsPresetsResource")) do
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
        for _, treeResource in ipairs(getResources(typeName)) do
            for _, node in ipairs(tryGet(treeResource.data, "nodes") or {}) do
                local costs = tryGet(node, "costs")
                if type(costs) == "number" and costs > 0 and trySet(node, "costs", 0) then
                    changed = changed + 1
                end
            end
        end
    end
    return changed
end

local function patchBalancingTable()
    if not (config.skillPointsPerLevel and config.skillPointsPerLevel > 0) then return 0 end

    local changed = 0
    for _, resource in ipairs(getResources("keen::BalancingTable")) do
        if trySet(resource.data, "skillPointsPerLevel", math.floor(config.skillPointsPerLevel)) then
            changed = changed + 1
        end
    end
    return changed
end

local function patchUpgradeRecipes()
    if not config.freeUpgradeRecipes then return 0 end

    local changed = 0
    for _, typeName in ipairs({ "keen::RecipeRegistryResource", "keen::DevRecipeRegistryResource" }) do
        for _, registryResource in ipairs(getResources(typeName)) do
            for _, recipe in ipairs(tryGet(registryResource.data, "recipes") or {}) do
                if tryGet(recipe, "isUpgrade") then
                    for _, input in ipairs(tryGet(recipe, "input") or {}) do
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
    local presets = getResources("keen::GameSettingsPresetsResource")
    local balancing = getResources("keen::BalancingTable")
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
        warn("[free-skills] Dismantle values differ from the ea_update_08 values")
    end
end

-- Warn when an enabled feature changed nothing; this usually means the game
-- data changed in a newer game version and the mod needs an update.
local function checkResults(nodes, balancing, upgrades)
    if config.freeSkillNodeCosts and nodes == 0 then
        warn("[free-skills] No skill tree nodes were changed, the skill tree data may have changed in this game version")
    end
    if config.skillPointsPerLevel and config.skillPointsPerLevel > 0 and balancing == 0 then
        warn("[free-skills] skillPointsPerLevel was not applied, the balancing table may have changed in this game version")
    end
    if config.freeUpgradeRecipes and upgrades == 0 then
        warn("[free-skills] No upgrade recipes were changed, the recipe data may have changed in this game version")
    end
end

print(string.format("[free-skills] v%s Loading...", VERSION))

if config.enabled then
    local nodes = patchSkillTreeNodes()
    local balancing = patchBalancingTable()
    local upgrades = patchUpgradeRecipes()

    print(string.format(
        "[free-skills] nodes=%d spp=%d upgrades=%d",
        nodes, balancing, upgrades
    ))
    checkResults(nodes, balancing, upgrades)

    if config.restoreDismantleValues then
        local restored = applyVanillaDismantleRestore()
        print(string.format("[free-skills] dismantleRestore=%d", restored))
        verifySalvage()
    end
else
    print("[free-skills] Disabled in config.txt")
end

print("[free-skills] Done.")
