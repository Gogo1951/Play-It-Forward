local _, ns = ...

ns.Fairness = {}
local Fairness = ns.Fairness

-- Spreads gifts out: a recipient is on cooldown until next seen at a higher level.

local function db()
	return ns.db.profile.recipients
end

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
	Names the server refused a mail to, this session only: a deleted character, a rename and a bad
	server minute are indistinguishable here. Not the cooldown -- a cooled-down player has had a
	gift, one of these never received anything.
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
	First candidate both free this pass and off cooldown, falling back to the first merely free, so
	an item is never stuck for want of a fresh face. Ordering belongs to RankCandidates.
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
