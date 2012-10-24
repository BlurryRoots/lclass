local setmetatable = setmetatable
local rawget = rawget
local getfenv = getfenv
local type = type

-------------------------------------------------------------------------------
-- __new()
-- Purpose: Creates a new object
-- Inpput: metatable
-- Output: object
-------------------------------------------------------------------------------
local function __new( metatable )
	local members = {}
	setmetatable( members, metatable )
	return members
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
			-- Call its constructor (function name:name( ... ) ... end) if it exists
			local v = rawget( metatable, name )
			if ( v ~= nil ) then v( object, ... ) end
			-- Return the new instance
			return object
		end
	} )
	-- Make the class available to the environment from which it was defined
	getfenv( 2 )[ name ] = metatable
	return function( base )
		metatable.__base = getfenv( 2 )[ base ]
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
	end
end
