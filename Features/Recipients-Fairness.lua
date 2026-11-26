local _, ns = ...

ns.Fairness = {}
local Fairness = ns.Fairness

-- On cooldown until next seen at a higher level. Session only, so every login makes everybody eligible again.
local given = {}

function Fairness:IsFresh(name, currentLevel)
	local record = given[name]
	if not record then
		return true
	end
	return (currentLevel or 0) > (record.level or 0)
end

function Fairness:Record(name, level)
	given[name] = { level = level }
end

-- Session only: a deleted character, a rename and a bad server minute look the same from here.
local unreachable = {}

function Fairness:MarkUnreachable(name)
	if name then
		unreachable[name] = true
	end
end

function Fairness:IsReachable(name)
	return not unreachable[name or ""]
end

-- Fresh first, then merely free, so an item is never stuck for want of a fresh face. Ordering belongs to RankCandidates.
function Fairness:PickFrom(ranked, isTaken)
	for _, person in ipairs(ranked) do
		-- Delivery records alts like anyone; this is the only thing keeping them off the cooldown.
		local fresh = person.alt or self:IsFresh(person.name, person.level)
		if not isTaken(person) and self:IsReachable(person.name) and fresh then
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
