-- SPDX-License-Identifier: GPL-3.0-or-later
-- Standalone runtime feasibility probe. No upstream MagicMarker code is included.
local ADDON = ...
local ICONS = { 8, 7, 6, 5, 4, 3, 2, 1 } -- skull through star
local MAX_RECORDS = 300
local frame = CreateFrame("Frame")
local db
local active = false

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "API unavailable"
    end
    return pcall(fn, ...)
end

local function buildInfo()
    local ok, version, build, dateText, interface = safeCall(GetBuildInfo)
    if not ok then
        return { error = tostring(version) }
    end
    return {
        version = type(version) == "string" and version or "?",
        build = tostring(build or "?"),
        date = tostring(dateText or "?"),
        interface = tostring(interface or "?"),
    }
end

local function timestamp()
    local ok, value = safeCall(date, "%Y-%m-%d %H:%M:%S")
    return ok and type(value) == "string" and value or "unknown-time"
end

local function readable(value)
    if type(issecretvalue) == "function" then
        local ok, secret = safeCall(issecretvalue, value)
        if not ok or type(secret) ~= "boolean" then return false end
        if secret then return false end
    end
    if type(canaccessvalue) == "function" then
        local ok, accessible = safeCall(canaccessvalue, value)
        if not ok or type(accessible) ~= "boolean" or not accessible then return false end
    end
    return true
end

local function safeText(value)
    if not readable(value) then return "<unreadable>" end
    local ok, result = pcall(tostring, value)
    if not ok or type(result) ~= "string" or not readable(result) then return "<unreadable>" end
    return result
end

local function knownBoolean(value)
    return readable(value) and type(value) == "boolean"
end

local function addRecord(kind, fields)
    if not db then return end
    local rec = fields or {}
    rec.time = timestamp()
    rec.kind = kind
    rec.build = db.build or buildInfo()
    local records = db.records
    records[#records + 1] = rec
    while #records > MAX_RECORDS do
        table.remove(records, 1)
    end
end

local function safeUnitString(api, unit)
    local ok, value = safeCall(api, unit)
    if ok and readable(value) and type(value) == "string" then return value end
    return nil
end

local function combatActive()
    local okLock, locked = safeCall(InCombatLockdown)
    if not okLock or not knownBoolean(locked) then
        return true, "combat-lockdown state unavailable"
    end
    if locked then return true, "combat lockdown" end
    local okCombat, fighting = safeCall(UnitAffectingCombat, "player")
    if not okCombat or not knownBoolean(fighting) then
        return true, "player combat state unavailable"
    end
    if fighting then return true, "player in combat" end
    return false
end

local function isValidIcon(value)
    if type(value) ~= "number" then return false end
    local ok, valid = pcall(function() return value >= 1 and value <= 8 and value % 1 == 0 end)
    return ok and valid
end

local function unitTokens()
    local units = { "player", "target", "focus", "mouseover" }
    for i = 1, 40 do
        units[#units + 1] = "nameplate" .. i
        units[#units + 1] = "raid" .. i
        units[#units + 1] = "raid" .. i .. "target"
    end
    for i = 1, 4 do
        units[#units + 1] = "party" .. i
        units[#units + 1] = "party" .. i .. "target"
    end
    return units
end

-- Return a known occupied-icon set, or fail closed if any readable unit's mark
-- cannot be interpreted. Unknown/out-of-range units cannot be inspected here.
local function scanOccupied()
    local occupied = {}
    for _, unit in ipairs(unitTokens()) do
        local okExists, exists = safeCall(UnitExists, unit)
        if not okExists then return nil, "UnitExists failed for " .. unit end
        if not knownBoolean(exists) then return nil, "UnitExists unreadable for " .. unit end
        if exists == true then
            local okIndex, index = safeCall(GetRaidTargetIndex, unit)
            if not okIndex then return nil, "GetRaidTargetIndex failed for " .. unit end
            if not readable(index) then
                return nil, "raid icon value is unreadable for " .. unit
            end
            if index ~= nil then
                if not isValidIcon(index) then
                    return nil, "raid icon value is unreadable for " .. unit
                end
                occupied[index] = true
                local guid = safeUnitString(UnitGUID, unit)
                db.observedIcons[index] = guid or "observed-unit"
            end
        end
    end
    for _, icon in pairs(db.assignments) do
        if isValidIcon(icon) then occupied[icon] = true end
    end
    for _, icon in pairs(db.pending) do
        if isValidIcon(icon) then occupied[icon] = true end
    end
    for icon in pairs(db.observedIcons) do
        if isValidIcon(icon) then occupied[icon] = true end
    end
    return occupied
end

local function identityFor(unit)
    local okGuid, guid = safeCall(UnitGUID, unit)
    if not okGuid or not readable(guid) or type(guid) ~= "string" then
        return nil, "unit identity unavailable"
    end
    if not guid or guid == "" then return nil, "unit identity unavailable" end
    local okName, name = safeCall(UnitName, unit)
    if not okName or not readable(name) or type(name) ~= "string" then name = nil end
    return guid, name or "unknown-name"
end

local function observeAssignment(guid, icon)
    for _, unit in ipairs(unitTokens()) do
        local observedGuid = safeUnitString(UnitGUID, unit)
        local sameOk, same = pcall(function() return observedGuid == guid end)
        if observedGuid and sameOk and same then
            local ok, current = safeCall(GetRaidTargetIndex, unit)
            local equalOk, equal = pcall(function() return current == icon end)
            if ok and readable(current) and isValidIcon(current) and equalOk and equal then
                return true, unit
            end
        end
    end
    return false
end

local function handleMouseover()
    if not active or not db then return end
    local unsafe, reason = combatActive()
    if unsafe then
        if not db.combatNoticeShown then
            addRecord("skipped-combat", { reason = reason })
            print("MMForeverProbe: stopped; " .. reason .. ". No mark attempted.")
            db.combatNoticeShown = true
        end
        active = false
        return
    end
    db.combatNoticeShown = false

    local okAlt, altDown = safeCall(IsAltKeyDown)
    if not okAlt or not knownBoolean(altDown) or not altDown then return end

    local okExists, exists = safeCall(UnitExists, "mouseover")
    if not okExists or not knownBoolean(exists) or not exists then return end
    local okAttack, canAttack = safeCall(UnitCanAttack, "player", "mouseover")
    if not okAttack or not knownBoolean(canAttack) or canAttack ~= true then
        addRecord("skipped-nonhostile", {})
        return
    end

    local okDead, dead = safeCall(UnitIsDeadOrGhost, "mouseover")
    if not okDead or not knownBoolean(dead) then
        addRecord("skipped-death-state-unknown", {})
        return
    end
    if dead then
        addRecord("skipped-dead", {})
        return
    end

    local guid, nameOrError = identityFor("mouseover")
    if not guid then
        addRecord("skipped-identity", { reason = nameOrError })
        return
    end
    local name = nameOrError

    local already = db.assignments[guid]
    if already then
        local observed, observedUnit = observeAssignment(guid, already)
        addRecord(observed and "observed-existing" or "already-assigned-unobserved", {
            unit = name, guid = guid, icon = already, observedUnit = observedUnit,
        })
        return
    end

    local pending = db.pending[guid]
    if pending then
        local observed, observedUnit = observeAssignment(guid, pending)
        if observed then
            db.pending[guid] = nil
            db.assignments[guid] = pending
            db.observedIcons[pending] = guid
            addRecord("mark-observed-later", { unit = name, guid = guid, icon = pending, observedUnit = observedUnit })
        else
            addRecord("pending-attempt-unobserved", { unit = name, guid = guid, icon = pending })
        end
        return
    end

    local okCurrent, currentIcon = safeCall(GetRaidTargetIndex, "mouseover")
    if not okCurrent then
        addRecord("skipped-current-mark-error", { unit = name, guid = guid, error = safeText(currentIcon) })
        return
    end
    if not readable(currentIcon) then
        addRecord("skipped-current-mark-unknown", { unit = name, guid = guid })
        return
    end
    if currentIcon ~= nil then
        if isValidIcon(currentIcon) then
            addRecord("skipped-already-marked", { unit = name, guid = guid, icon = currentIcon })
            db.observedIcons[currentIcon] = guid
        else
            addRecord("skipped-current-mark-unknown", { unit = name, guid = guid })
        end
        return
    end

    local occupied, occupancyError = scanOccupied()
    if not occupied then
        addRecord("skipped-occupancy-unknown", { unit = name, guid = guid, reason = occupancyError })
        return
    end
    local chosen
    for _, icon in ipairs(ICONS) do
        if not occupied[icon] then chosen = icon; break end
    end
    if not chosen then
        addRecord("skipped-icons-full", { unit = name, guid = guid })
        return
    end

    -- Reserve before the API call so repeat events cannot allocate this icon.
    -- A pcall returning true is only an attempted call, never proof of a mark.
    db.pending[guid] = chosen
    local okMark, markError = safeCall(SetRaidTarget, "mouseover", chosen)
    if not okMark then
        db.pending[guid] = nil
        active = false
        addRecord("setraidtarget-error-disarmed", {
            unit = name, guid = guid, icon = chosen, error = safeText(markError),
        })
        print("MMForeverProbe: SetRaidTarget raised an error; disarmed. See /mmf status and SavedVariables.")
        return
    end

    local observed, observedUnit = observeAssignment(guid, chosen)
    if observed then
        db.pending[guid] = nil
        db.assignments[guid] = chosen
        db.observedIcons[chosen] = guid
    end
    addRecord(observed and "mark-observed" or "mark-attempted-unobserved", {
        unit = name, guid = guid, icon = chosen, observedUnit = observedUnit,
        apiReturned = "pcall-ok",
    })
end

local function status()
    local build = buildInfo()
    print(string.format("MMForeverProbe active=%s build=%s version=%s interface=%s",
        active and "yes" or "no", build.build or "?", build.version or "?", build.interface or "?"))
    local count, pendingCount, observedCount = 0, 0, 0
    for guid, icon in pairs(db.assignments) do
        count = count + 1
        local seen, unit = observeAssignment(guid, icon)
        if seen then observedCount = observedCount + 1 end
        print(string.format("  assignment %d: icon=%s state=%s unit=%s",
            count, tostring(icon), seen and "observed" or "not currently observed", tostring(unit or "-")))
    end
    for guid, icon in pairs(db.pending) do
        pendingCount = pendingCount + 1
        local seen, unit = observeAssignment(guid, icon)
        if seen then
            db.pending[guid] = nil
            db.assignments[guid] = icon
            db.observedIcons[icon] = guid
            addRecord("mark-observed-later", { guid = guid, icon = icon, observedUnit = unit })
            observedCount = observedCount + 1
        end
    end
    print(string.format("  records=%d confirmed=%d pending=%d observed=%d (see SavedVariables for bounded details)",
        #db.records, count, pendingCount, observedCount))
    for i = math.max(1, #db.records - 4), #db.records do
        local r = db.records[i]
        print(string.format("  %s %s %s icon=%s error=%s", r.time or "?", r.kind or "?",
            r.unit or "", tostring(r.icon or "-"), tostring(r.error or r.reason or "-")))
    end
end

local function resetRecords()
    db.records = {}
    db.combatNoticeShown = false
    addRecord("diagnostics-reset", { note = "assignments retained; no world marks cleared" })
    print("MMForeverProbe: diagnostic records cleared; mark reservations retained.")
end

local function newTest()
    active = false
    db.records = {}
    db.assignments = {}
    db.pending = {}
    db.observedIcons = {}
    db.combatNoticeShown = false
    addRecord("new-test-session", { note = "reservations cleared; use a fresh unmarked test pack" })
    print("MMForeverProbe: reservations cleared. Start a fresh test only after verifying the pack has no marks.")
end

local function command(message)
    local cmd = (message or ""):match("^%s*(%S*)")
    cmd = (cmd or ""):lower()
    if cmd == "start" then
        local unsafe, reason = combatActive()
        if unsafe then
            print("MMForeverProbe: cannot start: " .. reason .. ".")
            addRecord("start-refused-combat", { reason = reason })
            return
        end
        db.build = buildInfo()
        active = true
        db.combatNoticeShown = false
        addRecord("started", {})
        print("MMForeverProbe: armed. Hold ALT and sweep hostile mouseovers while out of combat. No per-mob click is used.")
    elseif cmd == "stop" then
        active = false
        addRecord("stopped", {})
        print("MMForeverProbe: stopped.")
    elseif cmd == "status" then
        status()
    elseif cmd == "reset" then
        resetRecords()
    elseif cmd == "newtest" then
        newTest()
    else
        print("MMForeverProbe commands: /mmf start | stop | status | reset | newtest")
        print("reset clears diagnostic history only. newtest clears reservations; verify a fresh unmarked pack first. Neither clears in-world marks.")
    end
end

local function onEvent(_, event, ...)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local addonName, action = ...
        addRecord(event:lower(), { addon = safeText(addonName or "?"), action = safeText(action or "?") })
        local sameOk, sameAddon = pcall(function() return addonName == ADDON end)
        if sameOk and sameAddon then active = false end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if active then
            active = false
            addRecord("stopped-combat", { note = "disarmed on combat start; no combat marking attempted" })
            print("MMForeverProbe: disarmed on combat start.")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        db.combatNoticeShown = false
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        local ok, err = pcall(handleMouseover)
        if not ok then
            active = false
            addRecord("handler-error-disarmed", { error = safeText(err) })
            print("MMForeverProbe: unexpected handler error; disarmed. See SavedVariables.")
        end
    end
end

frame:SetScript("OnEvent", onEvent)

SLASH_MAGICMARKERFOREVERPROBE1 = "/mmf"
SlashCmdList.MAGICMARKERFOREVERPROBE = command

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(_, event, loaded)
    if event ~= "ADDON_LOADED" or loaded ~= ADDON then return end
    if type(MagicMarkerForeverProbeDB) ~= "table" then MagicMarkerForeverProbeDB = {} end
    db = MagicMarkerForeverProbeDB
    if type(db.records) ~= "table" then db.records = {} end
    if type(db.assignments) ~= "table" then db.assignments = {} end
    if type(db.pending) ~= "table" then db.pending = {} end
    if type(db.observedIcons) ~= "table" then db.observedIcons = {} end
    local reserved, reservationCount = {}, 0
    for guid, icon in pairs(db.assignments) do
        if type(guid) ~= "string" or not isValidIcon(icon) or reserved[icon] or reservationCount >= 8 then
            db.assignments[guid] = nil
        else
            reserved[icon] = true
            reservationCount = reservationCount + 1
        end
    end
    for guid, icon in pairs(db.pending) do
        if type(guid) ~= "string" or not isValidIcon(icon) or reserved[icon] or reservationCount >= 8 then
            db.pending[guid] = nil
        else
            reserved[icon] = true
            reservationCount = reservationCount + 1
        end
    end
    for icon, _ in pairs(db.observedIcons) do
        if not isValidIcon(icon) then
            db.observedIcons[icon] = nil
        elseif not reserved[icon] and reservationCount < 8 then
            reserved[icon] = true
            reservationCount = reservationCount + 1
            db.observedIcons[icon] = "persisted-observation"
        end
    end
    db.build = buildInfo()
    addRecord("loaded", {})
    for _, name in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UPDATE_MOUSEOVER_UNIT",
        "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
        pcall(frame.RegisterEvent, frame, name)
    end
    init:UnregisterEvent("ADDON_LOADED")
    print("MMForeverProbe loaded. /mmf for commands; build/interface recorded in SavedVariables.")
end)
