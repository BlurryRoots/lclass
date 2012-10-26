-------------------------------------------------------------------------------
-- Lua with Classes
-- lclass
-- Author: Andrew McWatters
-------------------------------------------------------------------------------
local setmetatable = setmetatable
local type = type
local error = error
local pcall = pcall
local unpack = unpack
local rawget = rawget
local getfenv = getfenv
local ipairs = ipairs

-------------------------------------------------------------------------------
-- __new()
-- Purpose: Creates a new object
-- Input: metatable
-- Output: object
-------------------------------------------------------------------------------
local function __new( metatable )
	local members = {}
	setmetatable( members, metatable )
	return members
end

-------------------------------------------------------------------------------
-- eventnames
-- Purpose: Provide a list of all inheritable internal event names
-------------------------------------------------------------------------------
local eventnames = {
	"__add", "__sub", "__mul", "__div", "__mod",
	"__pow", "__unm", "__len", "__lt", "__le",
	"__concat", "__call",
	"__tostring"
}

-------------------------------------------------------------------------------
-- __metamethod()
-- Purpose: Creates a filler metamethod for metamethod inheritance
-- Input: class - The class metatable
--		  eventname - The event name
-- Output: function
-------------------------------------------------------------------------------
local function __metamethod( class, eventname )
	return function( ... )
		local event = class.__base[ eventname ]
		if ( type( event ) ~= "function" ) then
			error( "attempt to call unimplemented metamethod '" .. eventname .. "'", 2 )
		end
		local returns = { pcall( event, ... ) }
		if ( returns[ 1 ] ~= true ) then
			error( returns[ 2 ], 2 )
		else
			return unpack( returns, 2 )
		end
	end
end

-------------------------------------------------------------------------------
-- class()
-- Purpose: Creates a new class
-- Input: name - Name of new class
-------------------------------------------------------------------------------
function class( name )
	local metatable		= {}
	metatable.__index	= metatable
	metatable.__type	= name
	-- Create a shortcut to name()
	setmetatable( metatable, {
		__call	= function( _, ... )
			-- Create a new instance of this object
			local object = __new( metatable )
			-- Call its constructor (function name:name( ... ) ... end) if it
			-- exists
			local v = rawget( metatable, name )
			if ( v ~= nil ) then v( object, ... ) end
			-- Return the new instance
			return object
		end
	} )
	-- Make the class available to the environment from which it was defined
	getfenv( 2 )[ name ] = metatable
	-- For syntactic sugar, return a function to set inheritance
	return function( base )
		-- Set our base class to the class definition in the function
		-- environment we called from
		metatable.__base = getfenv( 2 )[ base ]
		-- Overwrite our existing __index metamethod with one which checks our
		-- members, metatable, and base class, in that order
		metatable.__index = function( table, key )
			local h
			if ( type( table ) == "table" ) then
				local v = rawget( table, key )
				if ( v ~= nil ) then return v end
				v = rawget( metatable, key )
				if ( v ~= nil ) then return v end
				h = rawget( metatable.__base, "__index" )
				if h == nil then return nil end
			end
			if ( type( h ) == "function" ) then
				return h( table, key )
			else
				return h[ key ]
			end
		end
		-- Create inheritable metamethods
		for _, event in ipairs( eventnames ) do
			metatable[ event ] = __metamethod( metatable, event )
		end
	end
end
