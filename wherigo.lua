package.loaded['Wherigo'] = 1

_VERSION = "Lua 5.1"

DEBUG = false

Wherigo = {
	INVALID_ZONEPOINT 	= nil,
	
	MAINSCREEN			= "main",
	INVENTORYSCREEN 	= "inventory",
	ITEMSCREEN 			= "youSee",
	LOCATIONSCREEN		= "locations",
	TASKSCREEN			= "tasks",
	DETAILSCREEN 		= "detail",
	
	LOGDEBUG			= 150,
	LOGCARTRIDGE		= 151,
	LOGINFO				= 152,
	LOGWARNING			= 153,
	LOGERROR			= 154,
	
	CLASS_ZONE			= "Zone",
	CLASS_ZMEDIA		= "ZMedia",
	CLASS_ZCARTRIDGE	= "ZCartridge",
	CLASS_ZCHARACTER	= "ZCharacter",
	CLASS_ZCOMMAND		= "ZCommand",
	CLASS_ZINPUT		= "ZInput",
	CLASS_ZTASK			= "ZTask",
	CLASS_ZITEM			= "ZItem",
	CLASS_ZTIMER		= "ZTimer",
	CLASS_DISTANCE		= "Distance",
	CLASS_BEARING		= "Bearing",
	CLASS_ZONEPOINT		= "ZonePoint",
	
	_MBCallbacks = {},
	_GICallbacks = {}
	}



function Wherigo.MessageBox(t)
	local text = rawget(t, "Text")
	local media = rawget(t, "Media")
	local buttons = rawget(t, "Buttons")
	local callback = rawget(t, "Callback")
	--print("Message: ", text) 
	if media then
		--print("Media: ", media._id)
		media = media._id
	else
		media = ""
		end
	if buttons then
		button1 = rawget(buttons, 1)
		button2 = rawget(buttons, 2)
		--print("Buttons: ", button1, " _ ", button2)
		if button2 == nil then
			button2 = "" end
	else
		button1 = ""
		button2 = ""
		end
	if callback then
		table.insert(Wherigo._MBCallbacks, callback)
		callback = "1"
	else
		callback = "0"
		end
	WIGInternal.MessageBox(text, media, button1, button2, callback )
	end
function Wherigo._MessageBoxResponse(action)
	if # Wherigo._MBCallbacks > 0 then
		Wherigo.LogMessage("MessageBox Callback: [" .. action .. "]")
		callback = table.remove(Wherigo._MBCallbacks)
		callback(action)
	else
		error("Recieved MessageBox response to no request")
		end
	end
	
function Wherigo.Dialog(table)
	for k,v in pairs(table) do
		if type(v) == 'table' then
			text = rawget(v, "Text")
			media = rawget(v, "Media")
		else
			text = rawget(table, "Text")
			media = rawget(table, "Media")
			end
		if media then
			media = media._id
		else
			media = ""
			end
		WIGInternal.Dialog(text, media)
		end
	
	end

function Wherigo.PlayAudio(media)
	WIGInternal.PlayAudio(media._id)
	end
	
function Wherigo.ShowStatusText(text)
	-- for PPC devices only?
	WIGInternal.ShowStatusText(text)
	end

function Wherigo.VectorToZone(point, zone)
	if Wherigo.IsPointInZone (point, zone) then
		return Wherigo.Distance (0), Wherigo.Bearing (0) end
	local points = zone.Points
	local current, b = Wherigo.VectorToSegment (point, points[ #points ], points[1])
	for k,v in pairs (points) do
		if k > 1 then
			local this, tb = Wherigo.VectorToSegment (point, points[k - 1], points[k])
			if this.value < current.value then
				current = this
				b = tb end
			end
		end
	return current, b
	end

function Wherigo.VectorToSegment(point, p1, p2)
	local d1, b1 = Wherigo.VectorToPoint (p1, point)
	local d1 = math.rad (d1('nauticalmiles') / 60.)
	local ds, bs = Wherigo.VectorToPoint (p1, p2)
	local dist = math.asin (math.sin (d1) * math.sin (math.rad (b1.value - bs.value)))
	local dat = math.acos (math.cos (d1) / math.cos (dist))
	if dat <= 0 then
		return Wherigo.VectorToPoint (point, p1)
	elseif dat >= math.rad (ds('nauticalmiles') / 60.) then
		return Wherigo.VectorToPoint (point, p2) end
	local intersect = Wherigo.TranslatePoint (p1, Distance (dat * 60, 'nauticalmiles'), bs)
	return Wherigo.VectorToPoint (point, intersect)
	end

function Wherigo.Inject() end

function Wherigo._intersect(point, segment)
	--print("Loc:" .. point.latitude .. " " .. point.longitude .. " Loc:" .. segment[1].latitude .. " " .. segment[1].longitude .. " Loc:" .. segment[2].latitude .. " " .. segment[2].longitude)
	local lon1 = segment[1].longitude
	local lon2 = segment[2].longitude
	local lonp = point.longitude
	local lat
	if (lon2 - lon1) % 360 > 180 then
		-- lon1 > lon2
		if (lonp - lon2) % 360 > 180 or (lon1 - lonp) % 360 >= 180 or lon1 == lonp then
			-- lonp < lon2                  lonp > lon1   
			return 0
			end
		lat = segment[1].latitude + (segment[2].latitude - segment[1].latitude) * ((lon1 - lonp) % 360) / ((lon1 - lon2) % 360)
	else
		if (lonp - lon1) % 360 > 180 or (lon2 - lonp) % 360 >= 180 or lon2 == lonp then
			-- lonp < lon1                lonp > lon2
			return 0
			end
		lat = segment[1].latitude + (segment[2].latitude - segment[1].latitude) * ((lonp - lon1) % 360) / ((lon2 - lon1) % 360)
		end
	if lat > point.latitude then
		return 1
		end
	return 0
	end

function Wherigo.IsPointInZoneOld(point, zone)
	local num = 0
	local points = zone.Points
	-- Workaround for missing OriginalPoint (Whack a Lackey)
	local OriginalPoint;
	if not zone.OriginalPoint then
		local lat = 0
		local lon = 0
		for k,v in pairs(points) do
			lat = lat + v.latitude
			lon = lon + v.longitude
			end
		OriginalPoint = Wherigo.ZonePoint( lat/(#points), lon /(#points) )
	else
		OriginalPoint = zone.OriginalPoint
		end

	num = num + Wherigo._intersect(point, {points[ #points ], points[1]} )
	num = num + Wherigo._intersect(OriginalPoint, {points[ #points ], points[1]} )
	--print(num, points[1])
	for k, pnt in pairs(points) do
		if k > 1 then
			num = num + Wherigo._intersect(point, {points[k-1], points[k]} )
			num = num + Wherigo._intersect(OriginalPoint, {points[k-1], points[k]} )
			--print(num, pnt)
			end
		end
	return (num % 2) == 0
	end
	
function Wherigo.IsPointInZone(point, zone)
	-- fisrt go through Bounging Box
	if( zone._xmin == nil) then zone._calculateBoundingBox() end
	print(zone._xmin, point.longitude, zone._xmax)
	print(zone._ymin, point.latitude, zone._ymax)
	if  point.longitude < zone._xmin or
		point.longitude > zone._xmax or
		point.latitude < zone._ymin or
		point.latitude > zone._ymax then
		return false
		end
	
	
	-- from http://www.visibone.com/inpoly/
	-- easier way, without care of OriginalPoint
	local xold, yold, x1, y1, x2, y2
	local inside = false
	local points = zone.Points
	local xold = points[#points].longitude
	local yold = points[#points].latitude
	--print(point, zone)
	for k,p in pairs(points) do
		xnew = p.longitude
		ynew = p.latitude
		--print(xnew, xold, (xnew - xold)%360 < 180)
		if (xnew - xold)%360 < 180 then
		--if xnew > xold then
			x1=xold
			x2=xnew
			y1=yold
			y2=ynew
		else
			x1=xnew
			x2=xold
			y1=ynew
			y2=yold
			end
		if (x1 < point.longitude) and (point.longitude <= x2)
			and (point.latitude-y1)*(x2-x1)
				< (y2-y1)*(point.longitude-x1) then
				inside = not inside
			end
		xold = xnew
		yold = ynew
		end
	return inside
	end
	
function Wherigo.TranslatePoint(point, distance, bearing)
	local d = math.rad (distance.GetValue ('nauticalmiles') / 60.)
	local b
	if type(bearing) == 'table' then
		b = math.rad (bearing.value)
	else
		b = math.rad (bearing)
		end
	local lat1 = math.rad (point.latitude)
	local lat2 = math.asin (math.sin (lat1) * math.cos (d) + math.cos (lat1) * math.sin (d) * math.cos(b))
	local dlon = math.atan2 (math.sin(b) * math.sin (d) * math.cos (lat1), math.cos (d) - math.sin (lat1) * math.sin (lat2))
	return Wherigo.ZonePoint (math.deg (lat2), point.longitude + math.deg (dlon), point.altitude)
	end

function Wherigo.VectorToPoint(p1, p2)
	if p1.longitude == p2.longitude then
		local d = Wherigo.Distance ( math.abs(p1.latitude - p2.latitude) * 60, 'nauticalmiles')
		local b
		if p1.latitude <= p2.latitude then
			b = Wherigo.Bearing (0)
		else
			b = Wherigo.Bearing (180) end
		return d, b
		end
	local lat1 = math.rad (p1.latitude)
	local lon1 = math.rad (p1.longitude)
	local lat2 = math.rad (p2.latitude)
	local lon2 = math.rad (p2.longitude)
	local dist = 2 * math.asin (math.sqrt (
		math.sin ((lat1 - lat2) / 2) ^ 2 +
		math.cos (lat1) * math.cos (lat2) * math.sin ((lon1 - lon2) / 2) ^ 2
		))
	local bearing = math.atan2 (
		math.sin (lon2 - lon1) * math.cos(lat2),
		math.cos (lat1) * math.sin (lat2) - math.sin (lat1) * math.cos (lat2) * math.cos (lon2 - lon1)
		)
	return Wherigo.Distance (math.deg (dist) * 60, 'nauticalmiles'), Wherigo.Bearing (math.deg (bearing))
	end

function Wherigo.NoCaseEquals(f, s)
	return type(f) == type(s) and f:lower() == s:lower()
	end
	
function Wherigo.Command(text)
	if text == 'SaveClose' then
		Wherigo.LogMessage("Wherigo.Command: SaveClose");
		WIGInternal.RequestSync()
		WIGInternal.Close() -- with prompt ... todo
		exit(1)
	elseif text == 'DriveTo' then
		Wherigo.LogMessage("Wherigo.Command: DriveTo");
		--WIGInternal.DriveTo()
	elseif text == 'StopSound' then
		Wherigo.LogMessage("Wherigo.Command: StopSound");
		WIGInternal.StopSound()
	elseif text == 'Alert' then
		Wherigo.LogMessage("Wherigo.Command: Alert");
		WIGInternal.Alert()
		end
	end

function Wherigo.LogMessage(text, level)
	if type(text) == 'table' then
		level = text.Level
		text = text.Text
		end
	WIGInternal.LogMessage(text--[[, level]])
	end

function Wherigo.GetInput(input)
	-- ZInput is dialog to show and returns value from user
	Wherigo.LogMessage("ZInput:GetInput: " .. input.Name)

	table.insert(Wherigo._GICallbacks, input)
	local o = ""
	if input.InputType == "MultipleChoice" then
		local first = true
		for k, v in pairs(input.Choices) do
			if not first then
				o = o .. ";" end
			o = o .. v
			first = false
			end
		end
	local media
	if input.Media then
		media = input.Media._id
	else
		media = ""
		end
	
	WIGInternal.GetInput( input.InputType, input.Text, o, media)
	end
function Wherigo._GetInputResponse( response )
	if # Wherigo._GICallbacks > 0 then
		local input = table.remove(Wherigo._GICallbacks)
		Wherigo.LogMessage("ZInput:GetInput: " .. input.Name .. ": OnGetInput [" .. response .. "]")
		input.OnGetInput(input, response)
	else
		error("Recieved GetInput response to no request")
		end
	end

function Wherigo.ShowScreen(screen, item)
	if screen == Wherigo.DETAILSCREEN then
		if item == nil then
			error("Item must be specified") end
		Wherigo.LogMessage("ShowScreen: " .. screen .. " (" .. item.Name .. ")")
		WIGInternal.ShowScreen(screen, item.ObjIndex)
	else
		Wherigo.LogMessage("ShowScreen: " .. screen)
		WIGInternal.ShowScreen(screen, "")
		end
	end

function Wherigo.__tonumber(arg)
	if type(arg) == "table" then
		arg = arg.value
		end
	return arg
	end

--[[ A direction from one point to another ]]
Wherigo.Bearing = {}
Wherigo.Bearing_metatable = {
	__tostring = function( s )
		return "a Bearing instance"
		end,
	__call = function (s)
		return s.value
		end,
	__add = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) + Wherigo.__tonumber(op2) ) % 360
		end,
	__sub = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) - Wherigo.__tonumber(op2) ) % 360
		end,
	__mul = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) * Wherigo.__tonumber(op2) ) % 360
		end,
	__div = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) / Wherigo.__tonumber(op2) ) % 360
		end,
}
function Wherigo.Bearing.new(value)
	local self = { _classname = Wherigo.CLASS_BEARING}
	if type(value) == 'number' then
		self.value = value % 360
	else
		self.value = 0
		end
	
	setmetatable(self, Wherigo.Bearing_metatable)

	return self;
	end
setmetatable(Wherigo.Bearing, {
	__call = function( s, value)
		return Wherigo.Bearing.new(value)
		end,
	})

--[[ A distance between two points ]]
Wherigo.Distance = {}
Wherigo.Distance_metatable = {
	__tostring = function( s )
		return "a Distance instance"
		end,
	__call = function (s, units)
		return s.GetValue(units)
		end,
	__eq = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) == Wherigo.__tonumber(op2) )
		end,
	__lt = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) < Wherigo.__tonumber(op2) )
		end,
	__le = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) <= Wherigo.__tonumber(op2) )
		end,
	__add = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) + Wherigo.__tonumber(op2) )
		end,
	__sub = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) - Wherigo.__tonumber(op2) )
		end,
	__mul = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) * Wherigo.__tonumber(op2) )
		end,
	__div = function( op1, op2 )
		return ( Wherigo.__tonumber(op1) / Wherigo.__tonumber(op2) )
		end,
}
function Wherigo.Distance.new(value, units)
	units = units or 'meters'
	
	local self = { _classname = Wherigo.CLASS_DISTANCE}
	if units == 'meters' or units == 'm' then
		self.value = value
	elseif units == 'kilometres' or units == 'km' then
		self.value = value * 1000
	elseif units == 'feet' or units == 'ft' then
		self.value = value * 1609.344 / 5280.0
	elseif units == 'miles' or units == 'mi' then
		self.value = value * 1609.344
	elseif units == 'nauticalmiles' then
		self.value = value * 1852
	else
		error("Unknown units used in Distance: " .. units)
		end
	
	function self.GetValue(units)
		if type(units) == 'table' then
			units = units.units end
		units = units or 'meters'

		if units == 'meters' or units == 'm' then
			return self.value
		elseif units == 'kilometres' or units == 'km' then
			return self.value / 1000.0
		elseif units == 'feet' or units == 'ft' then
			return self.value / 1609.344 * 5280.0
		elseif units == 'miles' or units == 'mi' then
			return self.value / 1609.344
		elseif units == 'nauticalmiles' then
			return self.value / 1852
		else
			error("Unknown units used in Distance: " .. units)
			end
		
		end
	
	setmetatable(self, Wherigo.Distance_metatable)
	
	return self
	end
setmetatable(Wherigo.Distance, {
	__call = function (s, value, units)
		return Wherigo.Distance.new(value, units)
		end
	})

Wherigo.ZCommand = {}
Wherigo.ZCommand_metatable = {
	__tostring = function(s)
		return "a ZCommand instance"
		end,
	__index = function(t, key)
		if key == 'Enabled' then
			return t._enabled
			end
		end,
	__newindex = function(t, key, value)
		if key == 'Enabled' then
			if value ~= t._enabled then
				t._enabled = value
				Wherigo.LogMessage("ZCommand <" .. t.Text .. ">.Enabled = " .. Wherigo._bool2str(value))
				end
			end
		end,
}
function Wherigo.ZCommand.new(table)
	table = table or {}
	local self = {
		Text = table.Text or '',
		CmdWith = table.CmdWith or false,
			EmptyTargetListText = table.EmptyTargetListText or 'No target visible',
			MakeReciprocal = true,
			WorksWithAll = false,
			WorksWithList = table.WorksWithList or {}, -- Zcharacter, ZItem
		--Custom = true, -- doesn't matter
		_enabled = true,
		_classname = Wherigo.CLASS_ZCOMMAND,
		};
	if table.CmdWith ~= nil then
		self.CmdWith = table.CmdWith
		if table.MakeReciprocal ~= nil then
			self.MakeReciprocal = table.MakeReciprocal
			end
		if table.WorksWithAll ~= nil then
			self.WorksWithAll = table.WorksWithAll
			end
		if table.Enabled ~= nil then
			self._enabled = table.Enabled
			end
		end
	setmetatable(self, Wherigo.ZCommand_metatable)
	return self;
	end
function Wherigo.ZCommand:made( object )
	return (object._classname == Wherigo.CLASS_ZCOMMAND)
	end
setmetatable(Wherigo.ZCommand, {
	__call = function(s, table)
		return Wherigo.ZCommand.new(table)
		end
	})

Wherigo.ZObject = {} 
Wherigo.ZObject_metatable = {
	__index = function(t, key)
		if key == 'Active' then
			return t._active
		elseif k == 'CommandsArray' then
			local arr
			for i,v in ipairs(t.Commands) do
				table.insert(arr, v)
				end
			return arr -- runtime doesn't work with CommandsArray. Only export!
		elseif key == 'CorrectState' and t._classname == Wherigo.CLASS_ZTASK then
			return t._correct
		elseif key == 'Complete' and t._classname == Wherigo.CLASS_ZTASK then
			return t._complete
			end
		end,
	__newindex = function(t, key, value)
		if key == 'Active' then
			if value ~= t._active then
				t._active = value
				Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">.Active = " .. Wherigo._bool2str(value))
				if t._classname == Wherigo.CLASS_ZONE then
					if value then -- activating zone
						t.State = 'NotInRange'
						t._state = t.State
						t.Inside = false
						t._inside = t.Inside
						t._calculateBoundingBox()
						Wherigo.Zone._update( t )
					else
						Wherigo.Player._removeFromZone(t)
						end
					end
				if table.OnSetActive then
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">: START OnSetActive")
					t.OnSetActive(t)
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">: END__ OnSetActive")
					end
				end
			return
		elseif k == 'CommandsArray' then
			-- restore Commands from SaveGame
			for i,v in ipairs(value) do
				t.Commands[v.Keyword] = v;
				end
			return
		elseif t._classname == Wherigo.CLASS_ZTASK then
			if key == 'CorrectState' then
				if value ~= t._correct then
					t._correct = value
					Wherigo.LogMessage("ZTask <" .. t.Name .. ">.CorrectState = " .. Wherigo._bool2str(value))
					if t.OnSetCorrectState then
						Wherigo.LogMessage("ZTask <" .. t.Name .. ">: START OnSetCorrectState")
						t.OnSetCorrectState(t)
						Wherigo.LogMessage("ZTask <" .. t.Name .. ">: END__ OnSetCorrectState")
						end
					end
				return
			elseif key == 'Complete' then
				if value ~= t._complete then
					t._complete = value
					Wherigo.LogMessage("ZTask <" .. t.Name .. ">.Complete = " .. Wherigo._bool2str(value))
					if t.OnSetComplete then
						Wherigo.LogMessage("ZTask <" .. t.Name .. ">: START OnSetComplete")
						t.OnSetComplete(t)
						Wherigo.LogMessage("ZTask <" .. t.Name .. ">: END__ OnSetComplete")
						end
					end
				return
				end
			end
		rawset(t, key, value)
		end
}
function Wherigo.ZObject.new(cartridge, container )
	local self = {}
	if type(cartridge) == 'table' and not cartridge._classname then
		self = cartridge
		-- table args
		if self.Active ~= nil then
			self._active = self.Active
			self.Active = nil
		else
			self._active = true
			end
		if self.Complete ~= nil  then
			self._complete = self.Complete
			self.Complete = nil
		else
			self._complete = false
			end
		if self.CorrectState ~= nil  then
			self._correct = self.CorrectState
			self.CorrectState = nil
		else
			self._correct = false
			end
	else
		self = {
			Container = container or nil,
			Cartridge = cartridge or nil,
			_active = true,
		}
		end
	self.Name = self.Name or "(NoName)"
	self.Description = self.Description or -1
	self.Commands = self.Commands or {}
	if self.Visible == nil then
		self.Visible = true
		end
		--[[Description = "NoDescription",
		Icon = nil,
		Id = nil,
		Inventory = {}, -- ZObject
		Locked = false,
		Media = nil,
		Name = "NoName",
		ObjectLocation = Wherigo.INVALID_ZONEPOINT,
		Visible = true,]]--
	
	function self:Contains(obj)
		if obj == Wherigo.Player then
			return Wherigo.IsPointInZone(Wherigo.Player.ObjectLocation, self)
			end
		p = obj
		while true do
			if p == self then
				return true
				end
			if not p.Container then
				return false
				end
			p = p.Container
			end
		end
	function self:MoveTo(owner)
		if owner ~= nil then
			Wherigo.LogMessage("Move " .. self.Name .. " to " .. owner.Name)
			if owner == Wherigo.Player then
				table.insert(Wherigo.Player.Inventory, self)
			elseif self.Container == Wherigo.Player then
				for k,v in pairs(Wherigo.Player.Inventory) do
					if v == self then
						table.remove(Wherigo.Player.Inventory, k)
						end
					end
				end
		else
			Wherigo.LogMessage("Move " .. self.Name .. " to (nowhere)")
			end
		self.Container = owner
		end
	
	function self._is_visible()
		if not ((self.Active and self.Visible) or DEBUG) then
			return false
			end
		if not self.Container then
			return false
			end
		if not self.Container.Active or self.Container._classname ~= Wherigo.CLASS_ZONE then
			return false
			end
		if self.Container.ShowObjects == 'OnEnter' and self.Container.State ~= 'Inside' then
			return false
		elseif self.Container.ShowObjects == 'OnProximity' and self.Container.State ~= 'Inside' and self.Container.State ~= 'Proximity' then
			return false
		elseif self.Container.ShowObjects == 'Always' then
			return true
			end
		return true
		end
	
	function self._get_pos ()
		if self._classname == Wherigo.CLASS_ZONE then
			return self.OriginalPoint end
		if self._classname ~= Wherigo.CLASS_ZCHARACTER and self._classname ~= Wherigo.CLASS_ZITEM then
			return nil end
		if not self.ObjectLocation then
			if self.Container then
				return self.Container._get_pos ()
				end
			end
		return self.ObjectLocation
		end
	
	setmetatable(self, Wherigo.ZObject_metatable)
	
	-- initialization
	if self.Cartridge == nil then
		-- we don't have cartridge, so it is Player
		-- or Cartridge
		self.ObjIndex = -1
		return self
		end
	if Wherigo.ZCartridge._store ~= nil then
		--print(debug.traceback())
		self.ObjIndex = # self.Cartridge.AllZObjects + 1;
		table.insert(self.Cartridge.AllZObjects, self)
		end
	return self
	end
function Wherigo.ZObject:made( object )
	return true
	end
setmetatable(Wherigo.ZObject, {
	__call = function(s, cartridge, container)
		return Wherigo.ZObject.new(cartridge, container)
		end
})

Wherigo.ZonePoint = {} 
Wherigo.ZonePoint_metatable = {
	__tostring = function(s)
		return "a ZonePoint instance"
		end
}
function Wherigo.ZonePoint.new(lat, lon, alt)
	local self = { _classname = Wherigo.CLASS_ZONEPOINT}
	self.latitude = lat
	self.longitude = lon
	self.altitude = alt
	-- onchange update map --
	
	setmetatable(self, Wherigo.ZonePoint_metatable)
	return self
	end
function Wherigo.ZonePoint:made( object )
	return (object._classname == Wherigo.CLASS_ZONEPOINT)
	end
setmetatable(Wherigo.ZonePoint, {
	__call = function( s, lat, lon, alt)
		return Wherigo.ZonePoint.new(lat, lon, alt)
		end
	}) 

Wherigo.Zone = {
	STATES = {
		NotInRange,
		Distant,
		Proximity,
		Inside
		}
	}
Wherigo.Zone_metatable = {
	__tostring = function(s)
		return "a Zone instance"
		end
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.Zone_metatable[k] = v end
function Wherigo.Zone.new(cartridge)
	local self = Wherigo.ZObject.new(cartridge)
	self._classname = Wherigo.CLASS_ZONE
	table.insert(self.Cartridge.AllZones, self)
	self._state = Wherigo.Zone.NotInRange
	self._inside = false
	self.CurrentBearing = Wherigo.Bearing(0)
	self.CurrentDistance = Wherigo.Distance(0)
	
	--[[
	self.OriginalPoint = Wherigo.INVALID_ZONEPOINT
	
	self.Active = false
	self.Visible = false
	self.Name = "NoName"
	
	self.ShowObjects = "OnEnter"
	self.DistanceRange = Wherigo.Distance(10, 'ft')
	self.ProximityRange = Wherigo.Distance(30, 'ft')
	
		events OnDistant, OnEnter, OnNotInRange, OnExit, OnProximity, OnSetActive
	]]
	
	function self._calculateBoundingBox()
		self._xmin = self.Points[1].longitude
		self._xmax = self.Points[1].longitude
		self._ymin = self.Points[1].latitude
		self._ymax = self.Points[1].latitude
		for k,v in pairs(self.Points) do
			print(v.longitude, v.latitude)
			if v.longitude < self._xmin then
				self._xmin = v.longitude
			elseif v.longitude > self._xmax then
				self._xmax = v.longitude
				end
			if v.latitude < self._ymin then
				self._ymin = v.longitude
			elseif v.latitude > self._ymax then
				self._ymax = v.latitude
				end
			end
		print("----------------------------")
		print(self._xmin, self._xmax)
		print(self._ymin, self._ymax)
		end
	
	setmetatable(self, Wherigo.Zone_metatable) 
	return self
	end
function Wherigo.Zone:made( object )
	return (object._classname == Wherigo.CLASS_ZONE)
	end
function Wherigo.Zone._update( v )
	local inside = Wherigo.IsPointInZone (Wherigo.Player.ObjectLocation, v)
	print(v.Name, inside, v._inside, v.OriginalPoint, Wherigo.Player.ObjectLocation)
	if inside ~= v._inside then
		update_all = true
		v._inside = inside
		if inside then
			table.insert(Wherigo.Player.InsideOfZones, v)
			if v._state == 'NotInRange' and v.OnDistant then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onDistant")
				v.OnDistant(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onDistant")
				end
			if v._state ~= 'Proximity' and v.OnProximity then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onProximity")
				v.OnProximity(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onProximity")
				end
			if v.OnEnter then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onEnter")
				v.OnEnter(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onEnter")
				end
		else
			Wherigo.Player._removeFromZone(v)
			if v.OnExit then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onExit")
				v.OnExit(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onExit")
				end
			end
		end
	if inside then
		--Wherigo.LogMessage("Zone <" .. v.Name .. ">: Inside")
		v.State = 'Inside'
		v._state = v.State
	else
		-- if it is in table, remove
		-- how far?
		v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToZone (Wherigo.Player.ObjectLocation, v)
		--[[Wherigo.LogMessage(v.Name .. ": d:" .. tostring(v.CurrentDistance()) .. ", p:" ..
			tostring(v.ProximityRange()) .. ", d:" .. tostring(v.DistanceRange() ))]]
		if v.CurrentDistance() < v.ProximityRange() then
			if v._state == 'NotInRange' and v.OnDistant then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onDistant")
				v.OnDistant (v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onDistant")
				update_all = true
				end
			--Wherigo.LogMessage("Zone <" .. v.Name .. ">: Distant")
			v.State = 'Proximity'
		elseif v.DistanceRange() < 0 or v.CurrentDistance() < v.DistanceRange() then
			if v._state == 'Inside' and v.OnProximity then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onProximity")
				v.OnProximity(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onProximity")
				update_all = true
				end
			--Wherigo.LogMessage("Zone <" .. v.Name .. ">: Proximity")
			v.State = 'Distant'
		else
			if v._state == 'Inside' and v.OnProximity then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onProximity")
				v.OnProximity(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onProximity")
				update_all = true
				end
			if (v._state == 'Proximity' or v._state == 'Inside') and v.OnDistant then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onDistant")
				v.OnDistant(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onDistant")
				update_all = true
				end
			--Wherigo.LogMessage("Zone <" .. v.Name .. ">: NotInRange")
			v.State = 'NotInRange'
			end
		if v._state ~= v.State then
			--Wherigo.LogMessage("Zone <" .. v.Name .. ">: Other state: ")
			--Wherigo.LogMessage("Zone <" .. v.Name .. ">: " .. v.State)
			local s = v._state
			v._state = v.State
			local attr = 'On' .. v.State
			local event = rawget(v, attr)
			if event then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START on" .. v.State)
				event(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ on" .. v.State)
				update_all = true
				end
			end
		end
	return update_all
	end
setmetatable(Wherigo.Zone, {
	__call = function(s, cartridge)
		return Wherigo.Zone.new(cartridge)
		end
	}) 


Wherigo.ZCartridge = { }
function Wherigo.ZCartridge.new(  )
	Wherigo.ZCartridge._store = true
	local self = Wherigo.ZObject.new( ) 
	self._classname = Wherigo.CLASS_ZCARTRIDGE
	self._mediacount = -1
	self.AllZObjects = { self }
	self.ObjIndex = 1
	self.AllZCharacters = {}
	self.AllZItems = {}
	self.AllZones = {}
	self.AllZTimers = {}
	self.Company = Env._Company
	self.Activity = Env._Activity
	
	self.EmptyInventoryListText = 'No items'
	self.EmptyTaskListText = 'No new tasks'
	self.EmptyZonesListText = 'Nowhere to go'
	self.EmptyYouSeeListText = 'Nothing of interest'
	self.Complete = false -- maybe one of requirements to unlock on website
	
	--[[self.Name = 'Old name'
	self.Icon = Wherigo.ZMedia(self)
	self.Icon.Id = Env._IconId
	self.Media = Wherigo.ZMedia(self)
	self.Media.Id = Env._SplashId
	self.Icon = false
	self.MsgBoxCBFuncs = {}
	self.UseLogging = true
	self.Visible = true
	self.ZVariables = {}
	self.OnEnd = nil
	self.OnRestore = nil
	self.OnStart = nil
	self.OnSync = nil]]
	
	--Wherigo.Player.Cartridge = self
	
	self._mediacount = 1
	Wherigo.Player.Cartridge = self
	
	function self:RequestSync()
		Wherigo.LogMessage("ZCartridge:RequestSync")
		if self.OnSync then
			Wherigo.LogMessage("ZCartridge: START onSync")
			self.OnSync(self)
			Wherigo.LogMessage("ZCartridge: END__ onSync")
			end
		WIGInternal.RequestSync();
		end
	
	function self:GetAllOfType(t)
		if t == "Zone" then
			return self.AllZones
		elseif t == "ZItem" then
			return self.AllZItems
		elseif t == "Timer" then
			return self.AllZTimers
		elseif t == "ZCharacter" then
			return self.AllZCharacters
			end
		end
	
	function self._setup_media()
		self._sound = {}
		self._image = {}
		for k,v in pairs(self.AllZObjects) do
			if v.resources then
				if v.resources['Type'] == 'wav' or v.resources['Type'] == 'mp3' or v.resources['Type'] == 'fdl' then
					self._sound[k] = v -- nastavit to co je z hlavicky gwc
				else
					self._image[k] = v
					end
				end
			end
		end
	
	function self._update(position, t, accuracy, heading)
		for k,v in pairs(self.AllZObjects) do
			if v._classname == Wherigo.CLASS_ZTIMER and v._target ~= nil then
				v.Remaining = v._target - t
				end
			end
		local update_all = false
		if not position then
			return false end
		Wherigo.Player.ObjectLocation = position
		Wherigo.Player.PositionAccuracy = Distance(accuracy)
		Wherigo.Player._heading = heading
		Wherigo.Player.LastLocationUpdate = t
		for k,v in pairs(self.AllZObjects) do
			if v.Active then
				if (v._classname == Wherigo.CLASS_ZITEM and v.Container ~= Wherigo.Player)
						or v._classname == Wherigo.CLASS_ZCHARACTER then
					local pos = v._get_pos()
					if pos then
						v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToPoint(Wherigo.Player.ObjectLocation, pos)
						end
				elseif v._classname == Wherigo.CLASS_ZONE then
					update_all = Wherigo.Zone._update(v) or update_all
					end
				end
			end
		return update_all
		end
	
	return self
	end
function Wherigo.ZCartridge:made( object )
	return (object._classname == Wherigo.CLASS_ZCARTRIDGE)
	end
setmetatable(Wherigo.ZCartridge, {
	__call = function(s)
		return Wherigo.ZCartridge.new()
		end
	}) 

Wherigo.ZMedia = {}
Wherigo.ZMedia_metatable = {
	__tostring  = function(s)
		return "a ZMedia instance"
		end
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.ZMedia_metatable[k] = v end
function Wherigo.ZMedia.new( cartridge )
	self = Wherigo.ZObject.new(cartridge)
	self._classname = Wherigo.CLASS_ZMEDIA
	--[[
	self.AltText = ''
	self.Description = ''
	self.Id = ''
	self.Name = ''
	self.Resources = {Type='jpg', Filname='', Directives = {}}
	]]
	self._id = self.Cartridge._mediacount
	if self.Cartridge._mediacount > 0 then
		self.Cartridge._mediacount = self.Cartridge._mediacount + 1;
		end
	setmetatable(self, Wherigo.ZMedia_metatable) 

	return self
	end
function Wherigo.ZMedia:made( object )
	return (object._classname == Wherigo.CLASS_ZMEDIA)
	end
setmetatable(Wherigo.ZMedia, {
	__call = function(s, cartridge)
		return Wherigo.ZMedia.new(cartridge)
		end
	}) 

Wherigo.ZItem = {}
Wherigo.ZItem_metatable = {
	__tostring = function( s )
		return "a ZItem instance"
		end,
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.ZItem_metatable[k] = v end
function Wherigo.ZItem.new( cartridge, container )
	local self = Wherigo.ZObject.new(cartridge, container)
	self._classname = Wherigo.CLASS_ZITEM
	table.insert(self.Cartridge.AllZItems, self)
	self._target = nil
	
	setmetatable(self, Wherigo.ZItem_metatable)
	
	return self
	end
function Wherigo.ZItem:made( object )
	return (object._classname == Wherigo.CLASS_ZITEM)
	end
setmetatable(Wherigo.ZItem, {
	__call = function(s, cartridge, container)
		return Wherigo.ZItem.new( cartridge, container )
		end
	})

Wherigo.ZTask = {}
Wherigo.ZTask_metatable = {
	__tostring = function( s )
		return "a ZTask instance"
		end,
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.ZTask_metatable[k] = v end
function Wherigo.ZTask.new( cartridge, container )
	local self = Wherigo.ZObject.new( cartridge, container )
	self._classname = Wherigo.CLASS_ZTASK
	--[[self.Name = 'NoName'
	self.Description = ''
	self.Complete = false
	self.Correct = false]]--
	
	setmetatable(self, Wherigo.ZTask_metatable)
	-- events OnClick, SetCorrectState, OnSetComplete, OnSetActive
	return self
	end
function Wherigo.ZTask:made( object )
	return (object._classname == Wherigo.CLASS_ZTASK)
	end
setmetatable(Wherigo.ZTask, {
	__call = function(s, cartridge, container)
		return Wherigo.ZTask.new(cartridge, container)
		end
	}) 

Wherigo.ZTimer = {}
Wherigo.ZTimer_metatable = {
	__tostring = function( s )
		return "a ZTimer instance"
		end,
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.ZTimer_metatable[k] = v end
function Wherigo.ZTimer.new(cartridge)
	self = Wherigo.ZObject.new(cartridge)
	self.Type = self.Type or 'Countdown' -- Countdown or Interval
	self.Duration = self.Duration or -1
	self.Remaining = self.Remaining or -1
	--[[self.OnStart = nil
	self.OnStop = nil
	self.OnTick = nil]]
	
	self._classname = Wherigo.CLASS_ZTIMER
	self._target = nil -- target time
	
	function self:Start()
		if self._target ~= nil then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Not starting. Already running")
			return
			end
		Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Start")
		if self.OnStart then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: START onStart")
			self.OnStart(self)
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: END__ onStart")
			end
		if self.Remaining < 0 then
			self.Remaining = self.Duration
			end
		-- call native timer
		self._target = WIGInternal.addTimer(self.Remaining, self.ObjIndex);
		end
	function self:Stop()
		if self._target == nil then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Not stopping. Not running")
			return
			end
		Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Stop")
		-- native timer
		WIGInternal.removeTimer(self.ObjIndex)
		self._target = nil
		if self.onStop then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: START onStop")
			self.onStop(self)
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: END__ onStop")
			end
		
		end
	function self:Tick()
		Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Tick")
		if self.Type == 'Interval' then
			self._target = self._target + self.Duration
			now = WIGInternal.getTime()
			if self._target < now then
				self._target = now
				end
			self.Remaining = self._target - now
			WIGInternal.addTimer(self.Remaining, self.ObjIndex)
		else
			-- native timer
			self._target = nil
			self.Remaining = -1
			end
		if self.OnTick then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: START onTick")
			self.OnTick(self)
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: END__ onTick")
			end
		end

	setmetatable(self, Wherigo.ZTimer_metatable)
	
	return self
	end
function Wherigo.ZTimer:made( object )
	return (object._classname == Wherigo.CLASS_ZTIMER)
	end
setmetatable(Wherigo.ZTimer, {
	__call = function(s, cartridge)
		return Wherigo.ZTimer.new(cartridge)
		end
	})
function Wherigo.ZTimer._Tick(id)
	local t = cartridge.AllZObjects[id]
	if t._classname == Wherigo.CLASS_ZTIMER then
		t.Tick(t) end
	end

Wherigo.ZInput = {}
Wherigo.ZInput_metatable = {
	__tostring = function( s )
		return "a ZInput instance"
		end,
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.ZInput_metatable[k] = v end
function Wherigo.ZInput.new( cartridge )
	local self = Wherigo.ZObject.new( cartridge )
	self._classname = Wherigo.CLASS_ZINPUT
	--[[
	OnGetInput event
	]]
	
	setmetatable(self, Wherigo.ZInput_metatable)
	
	return self
	end
function Wherigo.ZInput:made( object )
	return (object._classname == Wherigo.CLASS_ZINPUT)
	end
setmetatable(Wherigo.ZInput, {
	__call = function(s, cartridge)
		return Wherigo.ZInput.new(cartridge)
		end
	})

Wherigo.ZCharacter = {}
Wherigo.ZCharacter_metatable = {
	__tostring = function( s )
		return "a ZCharacter instance"
		end,
}
for k,v in pairs(Wherigo.ZObject_metatable) do Wherigo.ZCharacter_metatable[k] = v end
function Wherigo.ZCharacter.new( cartridge, container )
	self = Wherigo.ZObject.new(cartridge, container)
	self._classname = Wherigo.CLASS_ZCHARACTER
	if Wherigo.ZCartridge._store ~= nil then
		table.insert(self.Cartridge.AllZCharacters, self)
		end
	--[[self.Name = "Unnamed"
	self.InsideZones = {}
	self.Inventory = {}
	self.ObjectLocation = Wherigo.INVALID_ZONEPOINT]]
	self.PositionAccuracy = Wherigo.Distance(5)
	
	setmetatable(self, Wherigo.ZCharacter_metatable)
	
	return self
	end
function Wherigo.ZCharacter:made( object )
	return (object._classname == Wherigo.CLASS_ZCHARACTER)
	end
setmetatable(Wherigo.ZCharacter, {
	__call = function(s, cartridge, container)
		return Wherigo.ZCharacter.new(cartridge, container)
		end
	}) 

--WIGInternal = {}

Wherigo.Player = Wherigo.ZCharacter.new()
Wherigo.Player.Name = Env._Player
Wherigo.Player.CompletionCode = Env._CompletionCode
Wherigo.Player.Inventory = {}
Wherigo.Player.InsideOfZones = {}
Wherigo.Player.CurrentDistance = nil
Wherigo.Player.CurrentBearing = nil
Wherigo.Player.ObjIndex = 0xabcd -- ID taken from Emulator to identify references

function Wherigo.Player:RefreshLocation()
	-- request refresh location ... useless?
	end
function Wherigo.Player._removeFromZone(zone)
	for i,t in pairs(Wherigo.Player.InsideOfZones) do
		if t == zone then
			table.remove(Wherigo.Player.InsideOfZones, i)
			end
		end
	end


--[[
for k,v in pairs(cartridge) do print(k,v) end
for k,v in pairs(Wherigo.Player.Inventory) do print(k,v) end
for k,v in pairs(Env.__propset) do print(k,v) end
for k,v in pairs(_G) do print(k,v) end
for k,v in pairs(zonePaloucek) do print(k,v) end

for k,v in pairs(cartridge.AllZObjects) do print(k,v, v.Active, v.Visible) end
]]

-- After runing script, setup media ?

-- onClick, Commands
Wherigo._callback = function(event, id)
	local t = cartridge.AllZObjects[id]
	if event == "OnClick" then
		if t.OnClick then
			Wherigo.LogMessage("ZCommand <" .. t.Name .. ">: " .. event .. " START")
			t[event](t)
			Wherigo.LogMessage("ZCommand <" .. t.Name .. ">: " .. event .. " END__")
			end
	else
		if t then
			local command = string.sub(event, 3)
			local c = t.Commands[command]
			if not c.CmdWith then
				if t[event] then
					Wherigo.LogMessage("ZCommand <" .. t.Name .. ">: " .. event .. " START")
					t[event](t)
					Wherigo.LogMessage("ZCommand <" .. t.Name .. ">: " .. event .. " END__")
				else
					Wherigo.LogMessage("ZCommand <" .. t.Name .. ">: " .. event .. " [no script]")
					end
			else
				local list = {}
				local choices = ""
				if c.WorksWithAll then
					for k,v in pairs(cartridge.AllZObjects) do
						if (v._classname == Wherigo.CLASS_ZCHARACTER or
							v._classname == Wherigo.CLASS_ZITEM)
							and v._is_visible() then
							table.insert(list, v);
							if # list ~= 0 then
								choices = choices .. ";"
								end
							choices = choices .. v.Name
							end
						end
				elseif c.WorksWithList then
					for k,v in pairs(c.WorksWithList) do
						if v._is_visible() then
							table.insert(list, v);
							if # list ~= 0 then
								choices = choices .. ";"
								end
							choices = choices .. v.Name
							end
						end
					end
				if # list == 0 then
					WIGInternal.Dialog("Nothing to command with", "")
					return
					end
				table.insert(Wherigo._GICallbacks, Wherigo._Internal)
				table.insert(Wherigo._CMDWithCallbacks, t[event])
				WIGInternal.GetInput("MultipleChoice", "Choose what to command with", choices, "");
				end
			end
		end
	end
Wherigo._CMDWithCallbacks = {}
Wherigo._Internal = {}
Wherigo._Internal.OnGetInput = function(self, choice)
	if # Wherigo._CMDWithCallbacks > 0 then
		local event = table.remove(Wherigo._CMDWithCallbacks)
		for k,v in pairs(cartridge.AllZObjects) do
			if (v._classname == Wherigo.CLASS_ZCHARACTER or
				v._classname == Wherigo.CLASS_ZITEM)
				and v._is_visible() and v.Name == choice then
				
				event(nil, v);
				return
				end
			end
		end
	end

Wherigo._getMediaField = function(field, t)
	if t then
		return ", \"" .. field .. "\": \"" .. Env.CartFolder .. t._id .. "." .. t.Resources[1].Type .. "\""
	else
		return "" end
	end

Wherigo._addCommands = function(item)
	v = ", \"commands\": ["
	first = true
	if item.Commands then
		for id,c in pairs(item.Commands) do
			if c.Enabled then
				if not first then
					v = v .. "," end
				v = v .. "{\"id\": \"" .. id .. "\", \"text\": \"" .. c.Text .. "\"}"
				first = false
				end
			end
		end
	return v .. "]"
	end

Wherigo._bool2str = function( b )
	if b then return "true"
	else return "false" end
	end
	
Wherigo._toJSON = function(str)
	if str ~= nil then
		return WIGInternal.escapeJsonString(str)
	else
		return ""
		end
	end

Wherigo._getUI = function()
	--[[for k,v in pairs(cartridge.AllZObjects) do
		print(v)
		if v._classname == Wherigo.CLASS_ZMEDIA and v.Resources then
			print(v.Resources[1].Type, v.Resources[1].Filename) end
		end]]
	return --"{" ..
		"\"locations\": " .. Wherigo._getLocations() .. ", "
		.. "\"youSee\": " .. Wherigo._getYouSee() .. ", "
		.. "\"inventory\": " .. Wherigo._getInventory() .. ", "
		.. "\"tasks\": " .. Wherigo._getTasks() -- .. "}"
		-- it is just without brackets around, so c++ can add more fields
	end

Wherigo._getLocations = function()
	local locations = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if v._classname == Wherigo.CLASS_ZONE and ((v.Active and v.Visible) or DEBUG) then
			if not first then
				locations = locations .. "," end
			locations = locations .. "{\"name\": \"" .. Wherigo._toJSON(v.Name) .. "\""
				.. ", \"description\": \"" .. Wherigo._toJSON(v.Description) .. "\""
			if v.OriginalPoint then
				locations = locations .. ", \"lat\": " .. v.OriginalPoint.latitude .. ", \"lon\": " .. v.OriginalPoint.longitude
				end
			if v.State == 'Inside' then
				locations = locations .. ", \"distance\": 0, \"bearing\": 0"
			else
				locations = locations .. ", \"distance\": " .. v.CurrentDistance("m") .. ", \"bearing\": " .. v.CurrentBearing("m")
				end
			locations = locations
				.. Wherigo._getMediaField("media", v.Media)
				.. Wherigo._getMediaField("icon", v.Icon)
				.. Wherigo._addCommands(v)
				.. ", \"id\": \"" .. k .. "\""
				.. "}"
			first = false
			end
		end
	return locations .. "]"
end

Wherigo._getInventory = function()
	local inventory = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if ((v.Active and v.Visible) or DEBUG) and v.Container == Wherigo.Player then
			if not first then
				inventory = inventory .. "," end
			inventory = inventory .. "{\"name\": \"" .. Wherigo._toJSON(v.Name)
				.. "\", \"description\": \"" .. Wherigo._toJSON(v.Description) .. "\""
				.. Wherigo._getMediaField("media", v.Media)
				.. Wherigo._getMediaField("icon", v.Icon)
				.. Wherigo._addCommands(v)
				.. ", \"id\": \"" .. k .. "\""
			if v.OnClick then
				inventory = inventory .. ", \"onclick\": true"
				end
			inventory = inventory .. "}"
			first = false
			end
		end
	
	return inventory .. "]"
end

Wherigo._getYouSee = function()
	local yousee = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if v._is_visible() and v.Container ~= Wherigo.Player then
			if not first then
				yousee = yousee .. "," end
			yousee = yousee .. "{\"name\": \"" .. Wherigo._toJSON(v.Name)
				.. "\", \"description\": \"" .. Wherigo._toJSON(v.Description) .. "\""
				.. Wherigo._getMediaField("media", v.Media)
				.. Wherigo._getMediaField("icon", v.Icon)
				.. Wherigo._addCommands(v)
				.. ", \"id\": \"" .. k .. "\""
			pos = v._get_pos()
			if pos and v.CurrentDistance then
				yousee = yousee .. ", \"distance\": " .. v.CurrentDistance("m")
					.. ", \"bearing\": " .. v.CurrentBearing("m")
					.. ", \"lat\": " .. pos.latitude
					.. ", \"lon\": " .. pos.longitude
				end
			if v.OnClick then
				yousee = yousee .. ", \"onclick\": true"
				end
			yousee = yousee .. "}"
			first = false
			end
		end
	
	return yousee .. "]"
end

Wherigo._getTasks = function()
	local tasks = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if v._classname == Wherigo.CLASS_ZTASK and v.Active and v.Visible then
			if not first then
				tasks = tasks .. "," end
			tasks = tasks .. "{\"name\": \"" .. Wherigo._toJSON(v.Name) .. "\""
				.. ", \"description\": \"" .. Wherigo._toJSON(v.Description) .. "\""
				.. Wherigo._getMediaField("media", v.Media)
				.. Wherigo._getMediaField("icon", v.Icon)
				.. Wherigo._addCommands(v)
				.. ", \"id\": \"" .. k .. "\""
				.. ", \"complete\": " .. Wherigo._bool2str(v.Complete)
			if v.OnClick then
				tasks = tasks .. ", \"onclick\": true"
				end
			tasks = tasks .. "}"
			first = false
			end
		end
	return tasks .. "]"
end
