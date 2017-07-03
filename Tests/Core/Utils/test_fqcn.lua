-- Tests for Core\Utils\FQCN.lua
TestGetFQCN = {}

-- Invalid parameters are supposed to use the currently logged in character
function TestGetFQCN:testInvalidParameters()

	-- Too few parameters given -> Use default character
	luaunit.assertEquals(T.Utils.GetFQCN(), "Duckwhale - Outland") -- This isn't technically invalid, but more of a shortcut
	luaunit.assertEquals(T.Utils.GetFQCN("asdf"), "asdf - Outland")
	luaunit.assertEquals(T.Utils.GetFQCN(nil, "asdf"), "Duckwhale - asdf")
	
	-- One or several parameters are of the wrong type
		luaunit.assertEquals(T.Utils.GetFQCN(1), "Duckwhale - Outland")
		luaunit.assertEquals(T.Utils.GetFQCN(nil, 2), "Duckwhale - Outland")
		luaunit.assertEquals(T.Utils.GetFQCN(1, 2), "Duckwhale - Outland")
		
		luaunit.assertEquals(T.Utils.GetFQCN(true), "Duckwhale - Outland")
		luaunit.assertEquals(T.Utils.GetFQCN(nil, true), "Duckwhale - Outland")
		luaunit.assertEquals(T.Utils.GetFQCN(true, true), "Duckwhale - Outland")
		
		luaunit.assertEquals(T.Utils.GetFQCN( {"Table 1"} ), "Duckwhale - Outland")
		luaunit.assertEquals(T.Utils.GetFQCN(nil, { "Table 2"} ), "Duckwhale - Outland")
		luaunit.assertEquals(T.Utils.GetFQCN( {"Table 1"}, {"Table 2"}), "Duckwhale - Outland")
	
end

-- Valid parameters -> Use them as character or realm names, respectively
function TestGetFQCN:testValidParameters()

	luaunit.assertEquals(T.Utils.GetFQCN("Character"), "Character - Outland")
	luaunit.assertEquals(T.Utils.GetFQCN("Character", "Realm"), "Character - Realm")

end
