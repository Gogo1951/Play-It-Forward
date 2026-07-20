local _, ns = ...

ns.Fairness = {}
local Fairness = ns.Fairness

--[[
	Spreads gifts out. Once someone receives an item they are on cooldown until next seen at a
	higher level. When an item has no fresh recipient, cooled-down players become eligible again
	rather than the item going unsent.
]]

local function db()
	return ns.db.profile.recipients
end

-- Fresh = never gifted, or seen since at a higher level than when last gifted.
function Fairness:IsFresh(name, currentLevel)
	local r = db()[name]
	if not r then
		return true
	end
	return (currentLevel or 0) > (r.level or 0)
end

function Fairness:Record(name, level)
	db()[name] = { level = level }
end

function Fairness:Reset()
	wipe(ns.db.profile.recipients)
end

--[[
	Names the server refused a mail to, this session only. The refusal could be a deleted
	character, a rename, or a bad server minute, and nothing here can tell them apart, so the
	name is set aside until the next login. Separate from the cooldown: a cooled-down player
	has had a gift, one of these never received anything.
]]
local unreachable = {}

function Fairness:MarkUnreachable(name)
	if name then
		unreachable[name] = true
	end
end

function Fairness:IsReachable(name)
	return not unreachable[name or ""]
end

--[[
	First candidate both free this pass and off cooldown, falling back to the first merely free,
	so an item is never stuck for want of a fresh face. Ordering belongs to RankCandidates; this
	knows only about fairness. Both passes skip anyone the mail system has already refused.
]]
function Fairness:PickFrom(ranked, isTaken)
	for _, person in ipairs(ranked) do
		if not isTaken(person) and self:IsReachable(person.name) and self:IsFresh(person.name, person.level) then
			return person
		end
	end
	for _, person in ipairs(ranked) do
		if not isTaken(person) and self:IsReachable(person.name) then
			return person
		end
	end
	return nil
end
