-- Offline behavioral checks for the feasibility probe. These mocks do not
-- emulate WoW security, server authority, or client behavior; they are not
-- evidence of in-game compatibility.
local probePath = (...)
assert(probePath, "pass path to Probe.lua")

local function fail(message)
    error(message, 2)
end
local function equal(actual, expected, label)
    if actual ~= expected then
        fail((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end
local function containsKind(db, kind)
    for _, record in ipairs(db.records) do
        if record.kind == kind then return true end
    end
    return false
end

local function scenario(setRaidTargetMode)
    local units = {}
    local combatLock, playerCombat, altDown = false, false, true
    local callCount = 0
    local frames = {}

    _G.MagicMarkerForeverProbeDB = nil
    _G.SlashCmdList = {}
    _G.SLASH_MAGICMARKERFOREVERPROBE1 = nil
    _G.CreateFrame = function()
        local f = { scripts = {}, events = {} }
        function f:SetScript(name, callback) self.scripts[name] = callback end
        function f:RegisterEvent(name) self.events[name] = true end
        function f:UnregisterEvent(name) self.events[name] = nil end
        frames[#frames + 1] = f
        return f
    end
    _G.GetBuildInfo = function() return "ForeverMock", "1", "date", 16001 end
    _G.issecretvalue = function(value)
        return (type(value) == "table" and value.secret == true)
            or value == "secret-guid" or value == "secret-name"
    end
    _G.date = function() return "2000-01-01 00:00:00" end
    _G.InCombatLockdown = function() return combatLock end
    _G.UnitAffectingCombat = function(unit)
        equal(unit, "player", "combat query unit")
        return playerCombat
    end
    _G.IsAltKeyDown = function() return altDown end
    _G.UnitExists = function(unit) return units[unit] ~= nil end
    _G.UnitCanAttack = function(_, unit) return units[unit] and units[unit].hostile or false end
    _G.UnitIsDeadOrGhost = function(unit) return units[unit] and units[unit].dead or false end
    _G.UnitGUID = function(unit) return units[unit] and units[unit].guid end
    _G.UnitName = function(unit) return units[unit] and units[unit].name end
    _G.GetRaidTargetIndex = function(unit) return units[unit] and units[unit].icon end
    _G.SetRaidTarget = function(unit, icon)
        callCount = callCount + 1
        if setRaidTargetMode == "throw" then error("mock protected failure") end
        if setRaidTargetMode ~= "noop" and units[unit] then units[unit].icon = icon end
    end

    assert(loadfile(probePath))("MagicMarkerForeverProbe")
    equal(#frames, 2, "frame count")
    frames[2].scripts.OnEvent(frames[2], "ADDON_LOADED", "MagicMarkerForeverProbe")

    local db = MagicMarkerForeverProbeDB
    local function addMob(unit, guid, icon)
        units[unit] = { guid = guid, name = unit, hostile = true, icon = icon }
    end
    local function mouseover(unit)
        units.mouseover = units[unit]
        frames[1].scripts.OnEvent(frames[1], "UPDATE_MOUSEOVER_UNIT")
    end
    local function start()
        SlashCmdList.MAGICMARKERFOREVERPROBE("start")
    end
    return {
        db = db, units = units, addMob = addMob, mouseover = mouseover,
        start = start, setCombat = function(lock, combat) combatLock, playerCombat = lock, combat end,
        setAlt = function(value) altDown = value end,
        combatEvent = function() frames[1].scripts.OnEvent(frames[1], "PLAYER_REGEN_DISABLED") end,
        calls = function() return callCount end,
        active = function() return true end,
    }
end

-- Disabled and ALT-up paths must not invoke the marking API.
do
    local s = scenario()
    s.addMob("target", "g-disabled")
    s.mouseover("target")
    equal(s.calls(), 0, "disabled API calls")
    s.start()
    s.setAlt(false)
    s.mouseover("target")
    equal(s.calls(), 0, "ALT-up API calls")
end

-- Combat start disarms; later mouseover while still held must not mark.
do
    local s = scenario()
    s.addMob("target", "g-combat")
    s.start()
    s.combatEvent()
    s.mouseover("target")
    equal(s.calls(), 0, "combat API calls")
    equal(s.db.assignments["g-combat"], nil, "combat reservation")
    if not containsKind(s.db, "stopped-combat") then fail("combat stop event missing") end
end

-- Repeated GUID mouseovers must only make one mark attempt and keep allocation.
do
    local s = scenario()
    s.addMob("target", "g-repeat")
    s.start()
    s.mouseover("target")
    local icon = s.db.assignments["g-repeat"]
    s.mouseover("target")
    equal(s.calls(), 1, "repeated GUID calls")
    equal(s.db.assignments["g-repeat"], icon, "repeated GUID icon")
end

-- Fill all eight icons with other readable units; no ninth allocation/call.
do
    local s = scenario()
    for i = 1, 8 do s.addMob("nameplate" .. i, "g-full-" .. i, i) end
    s.addMob("target", "g-extra")
    s.start()
    s.mouseover("target")
    equal(s.calls(), 0, "full-pool API calls")
    equal(s.db.assignments["g-extra"], nil, "full-pool reservation")
    if not containsKind(s.db, "skipped-icons-full") then fail("full-pool record missing") end
end

-- A protected-call exception is an error, never success, and is not reserved.
do
    local s = scenario("throw")
    s.addMob("target", "g-throw")
    s.start()
    s.mouseover("target")
    equal(s.db.assignments["g-throw"], nil, "throw reservation rollback")
    if not containsKind(s.db, "setraidtarget-error-disarmed") then fail("SetRaidTarget exception not recorded") end
    if containsKind(s.db, "mark-observed") then fail("throw incorrectly marked observed") end
    s.mouseover("target")
    equal(s.calls(), 1, "failed API retry suppression")
end

-- A silent no-op is an attempt with no observed mark, never mark-observed.
do
    local s = scenario("noop")
    s.addMob("target", "g-noop")
    s.start()
    s.mouseover("target")
    if not containsKind(s.db, "mark-attempted-unobserved") then fail("silent no-op not recorded as unobserved") end
    if containsKind(s.db, "mark-observed") then fail("silent no-op incorrectly marked observed") end
end

-- Secret-shaped identity/boolean values must not be used as table keys or
-- copied into logs. The harness models the issecretvalue predicate where the
-- real client exposes it; this does not reproduce WoW's secret-value runtime.
do
    local s = scenario()
    s.addMob("target", "g-secret")
    s.start()
    s.units.target.guid = "secret-guid"
    s.mouseover("target")
    equal(s.calls(), 0, "secret GUID API calls")
    equal(s.db.assignments["secret-guid"], nil, "secret GUID key")
    for _, record in ipairs(s.db.records) do
        if record.guid == "secret-guid" or record.unit == "secret-guid" then
            fail("secret-shaped value copied into record")
        end
    end
end

-- A readable old mark seen during occupancy discovery remains reserved even
-- after that unit token disappears, and secret GUID text is never persisted.
do
    local s = scenario()
    s.addMob("nameplate1", "secret-guid", 8)
    s.addMob("target", "g-new")
    s.start()
    s.mouseover("target")
    s.units.nameplate1 = nil
    equal(s.db.observedIcons[8], "observed-unit", "secret observed GUID fallback")
    equal(s.db.assignments["g-new"], 7, "observed mark retained after unit disappears")
end

-- Dead targets must be skipped before any raid-icon call.
do
    local s = scenario()
    s.addMob("target", "g-dead")
    s.units.target.dead = true
    s.start()
    s.mouseover("target")
    equal(s.calls(), 0, "dead target API calls")
    equal(s.db.assignments["g-dead"], nil, "dead target reservation")
    if not containsKind(s.db, "skipped-dead") then fail("dead target skip not recorded") end
end

print("mock_probe: PASS (offline mocks only; not in-game evidence)")
