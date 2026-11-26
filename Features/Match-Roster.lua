local _, ns = ...

local MatchList = ns.MatchList

local pools = {} -- classToken -> { {name, level, class, area}, ... } from /who, the guild roster and your alts
local seenPlayer = {} -- qualified identity -> its pool entry, dedupes across sources and chunks
-- Session total for the roster report.
local tooLow = 0

-- RescanBags needs no bump: it replaces every item table, caches included.
local poolsGeneration = 0

function MatchList:Pools()
	return pools
end

--[[
	Never reads item.recipient, so assignments keep it valid. Settings it reads bump no generation:
	their setters' ns.RefreshMailWindow rescan replaces the items. Shared by reference: never mutate it.
]]
function MatchList:Candidates(item)
	if item._candidates and item._candidatesGeneration == poolsGeneration then
		return item._candidates
	end
	local ranked = ns.Matcher:RankCandidates(item, pools)
	item._candidates, item._candidatesGeneration = ranked, poolsGeneration
	return ranked
end

-- Returns how many pool entries changed; the shuffle is rolled once at entry so equals hold still.
function MatchList:AddResults(results)
	local changed = 0
	-- A /who across your own level answers with you too, and mail to yourself is refused.
	local me = ns.QualifyPlayerName(ns.PlayerName())
	for _, person in ipairs(results) do
		--[[
			The one level floor, at the door every source uses. Alts excepted: the floor guesses at
			strangers' bank alts, and a ticked alt is the player's own answer.
		]]
		if not person.alt and (person.level or 0) < ns.Data.MIN_RECIPIENT_LEVEL then
			tooLow = tooLow + 1
		elseif person.alt or ns.QualifyPlayerName(person.name) ~= me then
			-- /who answers bare where the guild roster qualifies; the entry keeps its name as the address.
			local key = ns.QualifyPlayerName(person.name) or person.name
			local known = seenPlayer[key]
			if known then
				-- The later sighting still has something to add: where they rank, a level gained, or where they are now.
				local entryChanged = false
				if person.alt and not known.alt then
					known.alt = true
					known.altKey = known.altKey or person.altKey
					entryChanged = true
				end
				if person.guild and not known.guild then
					known.guild = true
					known.guildName = person.guildName
					entryChanged = true
				end
				if type(person.level) == "number" and person.level > (known.level or 0) then
					known.level = person.level
					entryChanged = true
				end
				if type(person.area) == "string" and person.area ~= "" and person.area ~= known.area then
					known.area = person.area
					entryChanged = true
				end
				if entryChanged then
					changed = changed + 1
				end
			else
				person.shuffle = math.random()
				seenPlayer[key] = person
				pools[person.class] = pools[person.class] or {}
				table.insert(pools[person.class], person)
				changed = changed + 1
			end
		end
	end
	-- Only on a change: the guild roster re-answers in full every pull.
	if changed > 0 then
		poolsGeneration = poolsGeneration + 1
	end
	return changed
end

--[[
	Guild state is read only at pool entry, so My Guilds changes need this. Dropped rather than
	demoted: a roster member was never a stranger anybody searched for, and /who can pool them again.
]]
function MatchList:RecheckGuildmates()
	local guildOf = ns.Guild:WhoLookup()
	local dropped = 0
	for _, pool in pairs(pools) do
		for index = #pool, 1, -1 do
			local person = pool[index]
			if person.guild and not person.alt and person.guildName then
				local guildmate, ignored = guildOf(person.guildName, person.name)
				if ignored or not guildmate then
					table.remove(pool, index)
					seenPlayer[ns.QualifyPlayerName(person.name) or person.name] = nil
					dropped = dropped + 1
				end
			end
		end
	end
	if dropped > 0 then
		poolsGeneration = poolsGeneration + 1
	end
	return dropped
end

-- How many candidates the level floor turned away this session, for the roster report.
function MatchList:TooLowCount()
	return tooLow
end
