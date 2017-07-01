-- Tests for Core\Utils\Colours.lua
TestHexToRGB = {}
TestRGBToHex = {}

-- Since value is nil, it should not format anything (and return nothing, which implicitly means "returns nil")
function TestHexToRGB:testInvalidParameters() 

	local R = { 0, 0, 0 }
	
	luaunit.assertEquals(T.Utils.HexToRGB(), R)
	luaunit.assertEquals(T.Utils.HexToRGB(42), R)
	luaunit.assertEquals(T.Utils.HexToRGB( {"Hello World"}), R )
	luaunit.assertEquals(T.Utils.HexToRGB(""), R)
	luaunit.assertEquals(T.Utils.HexToRGB("asdf"), R)
	luaunit.assertEquals(T.Utils.HexToRGB("asdfgh"), R)
	luaunit.assertEquals(T.Utils.HexToRGB("12345"), R)
	luaunit.assertEquals(T.Utils.HexToRGB("#1234567"), R)
	
end

function TestHexToRGB:testValidParameters() 

	local R = { 255, 254, 253 }

	local function compareResult(str)
	
		local r, g, b = T.Utils.HexToRGB(str)
		local R = { r, g, b }
		return R
		
	end
	
	luaunit.assertEquals(compareResult("FFFEFD"), R)
	luaunit.assertEquals(compareResult("#FFFEFD"), R)
	luaunit.assertEquals(compareResult("fffefd"), R)
	luaunit.assertEquals(compareResult("#fffefd"), R)
	
end

-- Invalid parameters should always return the colour "white" (code: 00000 = rgb {0, 0, 0} )
function TestRGBToHex:testInvalidParameters_NoPrefix()

	-- Too few parameters
	luaunit.assertEquals(T.Utils.RGBToHex(), "000000")
	--luaunit.assertEquals(T.Utils.RGBToHex(1), "000000")
	--luaunit.assertEquals(T.Utils.RGBToHex(1, 2), "000000")
	
	-- Parameters of the wrong type
	luaunit.assertEquals(T.Utils.RGBToHex( { "Table 1"} ), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex( { "Table 1"}, { "Table 2"} ), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex( { "Table 1"}, { "Table 2"}, { "Table 3"} ), "000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex(true), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(true, true), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(true, true, true), "000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex(""), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex("", ""), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex("", "", ""), "000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex("123"), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex("123", "123"), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex("123", "123", "123"), "000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex("12345678"), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex("12345678", "12345678"), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex("12345678", "12345678", "12345678"), "000000")
	
	-- Parameters that are numbers, but too high to convert to RGB colour codes
	luaunit.assertEquals(T.Utils.RGBToHex(0, 0, 500), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(0, 500, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(500, 0, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(0, 400, 500), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(300, 400, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(300, 0, 500), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(300, 400, 500), "000000")
	
	-- Parameters that are numbers, but too low to convert to RGB colour codes
	luaunit.assertEquals(T.Utils.RGBToHex(0, 0, -3), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(0, -2, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(-1, 0, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(0, -2, -3), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(-1, -2, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(-1, 0, -3), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(-1, -2, -3), "000000")
	
end

-- Invalid parameters should always return the colour "white" (code: #00000 = rgb {0, 0, 0} )
function TestRGBToHex:testInvalidParameters_AddPrefix()

	-- Too few parameters
	luaunit.assertEquals(T.Utils.RGBToHex(nil, nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex(0, nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex(1, 2, nil, true), "#000000")
	
	-- Parameters of the wrong type
	luaunit.assertEquals(T.Utils.RGBToHex( { "Table 1"} , nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex( { "Table 1"}, { "Table 2"}, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex( { "Table 1"}, { "Table 2"}, { "Table 3"}, true ), "#000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex(true, nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex(true, true, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex(true, true, true, true), "#000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex("", nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex("", "", nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex("", "", "", true), "#000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex("123", nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex("123", "123", nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex("123", "123", "123", true), "#000000")
	
	luaunit.assertEquals(T.Utils.RGBToHex("12345678", nil, nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex("12345678", "12345678", nil, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex("12345678", "12345678", "12345678", true), "#000000")
	
end

function TestRGBToHex:testValidParameters_NoPrefix()
	
	-- Omit addPrefix parameter
	luaunit.assertEquals(T.Utils.RGBToHex(255, 255, 255), "FFFFFF")
	luaunit.assertEquals(T.Utils.RGBToHex(0, 0, 0), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(17, 17, 17), "111111")
	
	-- Set addPrefix parameter to false
	luaunit.assertEquals(T.Utils.RGBToHex(255, 255, 255, false), "FFFFFF")
	luaunit.assertEquals(T.Utils.RGBToHex(0, 0, 0, false), "000000")
	luaunit.assertEquals(T.Utils.RGBToHex(17, 17, 17, false), "111111")
	
end

function TestRGBToHex:testValidParameters_AddPrefix()
	
	luaunit.assertEquals(T.Utils.RGBToHex(255, 255, 255, true), "#FFFFFF")
	luaunit.assertEquals(T.Utils.RGBToHex(0, 0, 0, true), "#000000")
	luaunit.assertEquals(T.Utils.RGBToHex(17, 17, 17, true), "#111111")
	
end