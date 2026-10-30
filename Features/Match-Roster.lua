local _, ns = ...

--[[
	Who is on the roster: your alts, and everybody /who and the guild roster turned up this session, pooled by
	class and deduped, and the ranked candidates each item draws from them. File-scope, so the
	roster survives a window close like the rest of Features/Match-List.lua's state.
]]

local MatchList = ns.MatchList

local pools = {} -- classToken -> { {name, level, class, area}, ... } from /who, the guild roster and your alts
local seenPlayer = {} -- qualified identity -> its pool entry, dedupes across sources and chunks
--[[
	Session total for the roster report: the report explains what a search found, and who was too
	low is part of that.
]]
local tooLow = 0

--[[
	Bumped whenever the pools change, which is what makes the candidate cache below safe to hand
	out. A counter rather than a walk of every item: one increment per query, where clearing a
	field per item costs the scan it was meant to save. Features/Match-List.lua's RescanBags has no bump -- it
	replaces every item table outright, so no cache survives it anyway.
]]
local poolsGeneration = 0

function MatchList:Pools()
	return pools
end

--[[
	RankCandidates sorts every admitted class against every pooled player, and the same answer is
	asked for repeatedly -- once per Assign, once per dropdown open, and once per mouse-over of a
	recipient button, which has no ceiling. Its inputs are the pools, each pooled player's level,
	guild and zone included, and the item's own verdict and band: it never reads item.recipient,
	so an assignment does not invalidate a cached answer.

	Settings are inputs as well: profile.sendToAlts and each alt's include, specs and gear levels on
	the My Alts panel, read by AltWants in Features/Match-Ranking.lua. No generation
	covers them. The cache stays safe
	only because their setters call ns.RefreshMailWindow, whose rescan replaces every item table
	and every cached answer with it, or marks the scan stale so the next one does.

	HANDED OUT BY REFERENCE, NEVER COPIED. Every caller only reads it, and one that sorted or
	removed in place would poison the cache for everybody after it.
]]
function MatchList:Candidates(item)
	if item._candidates and item._candidatesGeneration == poolsGeneration then
		return item._candidates
	end
	local ranked = ns.Matcher:RankCandidates(item, pools)
	item._candidates, item._candidatesGeneration = ranked, poolsGeneration
	return ranked
end

--[[
	Folds one query's results into the roster, deduped. The shuffle key is rolled once as a player
	enters the pool, so the order among equals holds still instead of moving between renders.
	Returns how many pool entries changed: new players, plus known ones who just became guildmates,
	were seen at a higher level or turned up in a different zone.
]]
function MatchList:AddResults(results)
	local changed = 0
	for _, person in ipairs(results) do
		--[[
			THE ONE LEVEL FLOOR, here rather than in either reader because this is the single door
			every recipient comes through: /who and the guild roster both arrive at this line, and
			a source added later inherits it without having to remember to. Counted before the
			dedupe, so the number means "people this rule turned away", not "people it turned away
			who were also new".
		]]
		if (person.level or 0) < ns.Data.MIN_RECIPIENT_LEVEL then
			tooLow = tooLow + 1
		else
			--[[
				DEDUPED ON THE QUALIFIED IDENTITY, NOT THE RAW NAME. /who answers bare for
				somebody on your own realm where the guild roster qualifies the same character,
				so one person arrives under two spellings and a raw-string check pools them
				twice -- two entries, two items, two parcels in one mailbox. The entry itself
				keeps the name it arrived under, because that is the address.
			]]
			local key = ns.QualifyPlayerName(person.name) or person.name
			local known = seenPlayer[key]
			if known then
				-- The later sighting still has something to add: where they rank, a level gained, or where they are now.
				local entryChanged = false
				if person.alt and not known.alt then
					known.alt = true
					entryChanged = true
				end
				if person.guild and not known.guild then
					known.guild = true
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
	--[[
		Only when a pool entry changed: a query returning nothing new leaves the ranking unchanged,
		and bumping would throw the cache away once per press for an answer that could not have
		moved -- the common case, since the guild roster re-answers in full every time. A known
		player turning out to be a guildmate or an alt does change it, through where they rank, and so
		does one seen at a higher level, through their band and the gift cooldown, or in a new
		zone, through their placement.
	]]
	if changed > 0 then
		poolsGeneration = poolsGeneration + 1
	end
	return changed
end

-- How many candidates the level floor turned away this session, for the roster report.
function MatchList:TooLowCount()
	return tooLow
end
