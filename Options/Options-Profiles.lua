local _, ns = ...

--------------------------------------------------------------------------------
-- Profiles Panel
--------------------------------------------------------------------------------

function ns.BuildProfilesOptions()
	return LibStub("AceDBOptions-3.0"):GetOptionsTable(ns.db)
end
