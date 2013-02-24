package.loaded['Wherigo'] = 1

_VERSION = "Lua 5.1"

Wherigo = {
	INVALID_ZONEPOINT 	= 0,
	
	MAINSCREEN			= 0,
	INVENTORYSCREEN 	= 1,
	ITEMSCREEN 			= 2,
	LOCATIONSCREEN		= 3,
	TASKSCREEN			= 4,
	DETAILSCREEN 		= 10,
	
	LOGDEBUG			= 150,
	LOGCARTRIDGE		= 151,
	LOGINFO				= 152,
	LOGWARNING			= 153,
	LOGERROR			= 154,
	
	_MBCallbacks = {},
	_GICallbacks = {}
	}

function Wherigo._intersect(point, segment)
	local lon1 = segment[1].longitude
	local lon2 = segment[2].longitude
	local lonp = point.longitude
	if (lon2 - lon1) % 360 > 180 then
		-- lon1 > lon2
		if (lonp - lon2) % 360 > 180 or (lon1 - lonp) % 360 >= 180 or lon1 == lonp then
			return 0
			end
		lat = segment[1].latitude + (segment[2].latitude - segment[1].latitude) * ((lonp - lon2) % 360) / ((lon1 - lon2) % 360)
	else
		if (lonp - lon1) % 360 > 180 or (lon2 - lonp) % 360 >= 180 or lon2 == lonp then
			return 0
			end
		lat = segment[1].latitude + (segment[2].latitude - segment[1].latitude) * ((lonp - lon1) % 360) / ((lon2 - lon1) % 360)
		end
	if lat > point.latitude then
		return 1
		end
	return 0
	end


function Wherigo.MessageBox(t)
	local text = rawget(t, "Text")
	local media = rawget(t, "Media")
	local buttons = rawget(t, "Buttons")
	local callback = rawget(t, "Callback")
	--print("Message: ", text) 
	if media then
		--print("Media: ", media.Id)
		media = media.Id
	else
		media = nil
		end
	if buttons then
		button1 = rawget(buttons, 1)
		button2 = rawget(buttons, 2)
		--print("Buttons: ", button1, " _ ", button2)
	else
		button1 = nil
		button2 = nil
		end
	if callback then
		table.insert(Wherigo._MBCallbacks, callback)
		end
	WIGInternal.MessageBox(text, media, button1, button2, (callback ~= nil) )
	end
function Wherigo._MessageBoxResponse(action)
	if # Wherigo._MBCallbacks > 0 then
		callback = table.remove(Wherigo._MBCallbacks)
		callback(action)
	else
		error("Recieved MessageBox response to no request")
		end
	end
	
function Wherigo.Dialog(table)
	-- OK button
	-- sequence ???
	text = rawget(table, "Text")
	media = rawget(table, "Media")
	--print("Message: ", text)
	if media then
		--print("Media: ", media.Name)
		media = media.Id
	else
		media = nil
		end
	WIGInternal.MessageBox(text, media, nil, nil, false)
	end

function Wherigo.PlayAudio(media)
	WIGInternal.PlayAudio(media.Id)
	end
	
function Wherigo.ShowStatusText(text)
	-- for PPC devices only?
	end

function Wherigo.VectorToZone() end
function Wherigo.VectorToSegment() end
function Wherigo.Inject() end

function Wherigo.IsPointInZone(point, zone)
	local num = 0
	local points = zone.Points
	table.insert(points, points[0])
	local last
	for k, pnt in pairs(points) do
		if k > 1 then
			num = num + Wherigo._intersect(point, {last, pnt} )
			num = num + Wherigo._intersect(zone.OriginalPoint, {last, pnt} )
			end
		last = pnt
		end
	return (num % 2) == 0
	end
	
function Wherigo.TranslatePoint(point, distance, angle)
	
	return point
	end

function Wherigo.NoCaseEquals(f, s)
	return f == s
	end
	
function Wherigo.Command(text)
	-- SaveClose, DriveTo, StopSound, Alert
	end

function Wherigo.LogMessage(text, level)
	
	end
function Wherigo.LogMessage(table)
	text = rawget(table, "Text")
	level = rawget(table, "Level")
	Wherigo.LogMessage(text, level)
	end

function Wherigo.GetInput(input)
	-- ZInput is dialog to show and returns value from user
	table.insert(Wherigo._GICallbacks, input.OnGetInput)
	if input.Type == "Text" then
		
		end
	
	WIGInternal.GetInput( input.Text, input.Type) -- think about it
	end
function Wherigo._GetInputResponse( response )
	if # Wherigo._MBCallbacks > 0 then
		callback = table.remove(Wherigo._GICallbacks)
		callback(response)
	else
		error("Recieved GetInput response to no request")
		end
	end

function Wherigo.ShowScreen(screen, item)
	if screen == Wherigo.DETAILSCREEN and item == nil then
		error("Item must be specified")
	else
		WIGInternal.ShowScreen(screen, item)
		end
	end

--[[ A direction from one point to another ]]
Wherigo.Bearing = {}
function Wherigo.Bearing.new(value)
	local self = {}
	self.value = value % 360
	
	setmetatable(self, {
		__tostring = function( s )
			return "Bearing (" .. s.value .. "°)"
			end,
		})

	return self;
	end
setmetatable(Wherigo.Bearing, {
	__call = function( s, value)
		return Wherigo.Bearing.new(value)
		end
	})

--[[ A distance between two points ]]
Wherigo.Distance = {}
function Wherigo.Distance.new(value, units)
	units = units or 'meters'
	
	local self = {}
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
	
	function self.getValue(units)
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
	
	setmetatable(self, {
		__tostring = function( s )
			return "Distance (" .. s.value .. " meters)"
			end,
		__call = function (s, units)
			return self.getValue(units)
			end,
		__eq = function( op1, op2 )
			print("Comparing")
			return true
			end
		})
	
	return self
	end
setmetatable(Wherigo.Distance, {
	__call = function (s, value, units)
		return Wherigo.Distance.new(value, units)
		end
	})

Wherigo.ZCommand = {}
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
		Enabled = true,
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
			self.Enabled = table.Enabled
			end
		end
	setmetatable(self, {
		__tostring = function(s)
			return "Command (" .. s.Text .. ")"
			end
	})
	return self;
	end
setmetatable(Wherigo.ZCommand, {
	__call = function(s, table)
		return Wherigo.ZCommand.new(table)
		end
	})

Wherigo.ZObject = {} 
function Wherigo.ZObject.new(cartridge, container )
	local self = {
		Active = true,
		Container = container or nil,
		Cartridge = cartridge or nil,
		Commands = {},
		CommandsArray = {},
		CurrentBearing = Wherigo.Bearing(0),
		CurrentDistance = Wherigo.Distance(0),
		Description = "NoDescription",
		Icon = nil,
		Id = nil,
		Inventory = {}, -- ZObject
		Locked = false,
		Media = nil,
		Name = "NoName",
		ObjectLocation = Wherigo.INVALID_ZONEPOINT,
		Visible = true,
	}
	
	function self.Contains(obj)
		if obj == Player then
			return IsPointInZone(Player.ObjectLocation, self)
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
	function self.MoveTo(owner)
		self.Container = owner
		end
	
	
	-- initialization
	if cartridge == nil then
		-- todo
		--print(debug.traceback())
		self.ObjIndex = -1
		return self
		end
	if Wherigo.ZCartridge._store ~= nil then
		self.ObjIndex = # cartridge.AllZObjects + 1;
		table.insert(self.Cartridge.AllZObjects, self)
		end
	return self
	end
setmetatable(Wherigo.ZObject, {
	__call = function(s, cartridge, container)
		return Wherigo.ZObject.new(cartridge, container)
		end
})

Wherigo.ZonePoint = {} 
function Wherigo.ZonePoint.new(lat, lon, alt)
	local self = {}
	self.latitude = lat
	self.longitude = lon
	self.altitude = alt
	-- onchange update map --
	
	setmetatable(self, {
		__tostring = function( s )
			return "Zonepoint (" .. s.latitude .. ", " .. s.longitude .. ")"
			end,
	})
	return self
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
function Wherigo.Zone.new(cartridge)
	local self = Wherigo.ZObject(cartridge)
	self.OriginalPoint = Wherigo.INVALID_ZONEPOINT
	
	self._state = Wherigo.Zone.NotInRange
	self.Active = false
	self.Visible = false
	self.Name = "NoName"
	--[[
	
	self.ShowObjects = "OnEnter"
	self.DistanceRange = Wherigo.Distance(10, 'ft')
	self.ProximityRange = Wherigo.Distance(30, 'ft')
	
		events OnDistant, OnEnter, OnNotInRange, OnExit, OnProximity, OnSetActive
	]]
	
	setmetatable(self, {
		__tostring = function(s)
			if s.OriginalPoint == Wherigo.INVALID_ZONEPOINT then
				return "Zone " .. s.Name
			else
				return "Zone " .. s.Name .. " <" ..
					 rawget(getmetatable(s.OriginalPoint) or {}, "__tostring")(s.OriginalPoint)  .. ">"
				end
			end
	}) 
	
	return self
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
	self.AllZObjects = {}
	self.Name = 'Old name'
	self._mediacount = -1
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
	self.OnSync = nil
	
	Wherigo.Player.Cartridge = self
	
	self._mediacount = 1
	Wherigo.Player.Cartridge = self
	
	function RequestSync()
		-- save
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

	return self
	end
setmetatable(Wherigo.ZCartridge, {
	__call = function(s)
		return Wherigo.ZCartridge.new()
		end
	}) 

Wherigo.ZMedia = {}
function Wherigo.ZMedia.new( cartridge )
	self = Wherigo.ZObject(cartridge)
	--[[
	self.AltText = ''
	self.Description = ''
	self.Id = ''
	self.Name = ''
	self.Resources = {Type='jpg', Filname='', Directives = {}}
	]]
	self._id = cartridge._mediacount
	if cartridge._mediacount > 0 then
		cartridge._mediacount = cartridge._mediacount + 1;
		end
	return self
	end
setmetatable(Wherigo.ZMedia, {
	__call = function(s, cartridge)
		return Wherigo.ZMedia.new(cartridge)
		end
	}) 

Wherigo.ZItem = {}
function Wherigo.ZItem.new( cartridge, container )
	local self = Wherigo.ZObject(cartridge, container)
	return self
	end
setmetatable(Wherigo.ZItem, {
	__call = function(s, cartridge, container)
		return Wherigo.ZItem.new( cartridge, container )
		end
	})

Wherigo.ZTask = {}
function Wherigo.ZTask.new( cartridge, container )
	local self = Wherigo.ZObject( cartridge, container )
	return self
	end
setmetatable(Wherigo.ZTask, {
	__call = function(s, cartridge, container)
		return Wherigo.ZTask.new(cartridge, container)
		end
	}) 

Wherigo.ZTimer = {}
function Wherigo.ZTimer.new(cartridge)
	local self = Wherigo.ZObject(cartridge)
	self.Type = 'Countdown'
	self.Duration = -1
	self.Remaining = -1
	self.OnStart = nil
	self.OnStop = nil
	self.OnTick = nil
	self._target = nil
	
	function self.Start()
		if self._target ~= nil then
			print('Not starting timer: already running.')
			return
			end
		if self.OnStart then
			self.OnStart()
			end
		if self.Remaining < 0 then
			self.Remaining = self.Duration
			end
		-- call native timer
		end
	function self.Stop()
		if self._target == nil then
			print('Not stopping timer: not running.')
			return
			end
		-- native timer
		if self.onStop then
			self.onStop()
			end
		
		end
	function self.Tick()
		if self.Type == 'Interval' then
			self._target = self._target + self.Duration
			now = WIGInternal.time ()
			if self._target < now then
				self._target = now
				end
		else
			-- native timer
			self.Remaining = -1
			end
		if self.OnTick then
			self.OnTick()
			end
		end
	
	
	return self
	end
setmetatable(Wherigo.ZTimer, {
	__call = function(s, cartridge)
		return Wherigo.ZTimer.new(cartridge)
		end
	}) 

Wherigo.ZInput = {}
function Wherigo.ZInput.new( cartridge )
	local self = Wherigo.ZObject( cartridge )
	--[[
	OnGetInput event
	]]
	return self
	end
setmetatable(Wherigo.ZInput, {
	__call = function(s, cartridge)
		return Wherigo.ZInput.new(cartridge)
		end
	})

Wherigo.ZCharacter = {}
function Wherigo.ZCharacter.new( cartridge )
	self = Wherigo.ZObject.new(cartridge)
	self.Name = "Unnamed"
	self.InsideZones = {}
	self.Inventory = {}
	self.ObjectLocation = Wherigo.INVALID_ZONEPOINT
	self.PositionAccuracy = Wherigo.Distance(5)
	return self
	end
setmetatable(Wherigo.ZCharacter, {
	__call = function(s, cartridge, container)
		return Wherigo.ZCharacter.new(cartridge, container)
		end
	}) 

--WIGInternal = {}
	-- nabalit vnitrni funkce v C++

Wherigo.Player = Wherigo.ZCharacter.new()
Wherigo.Player.Name = Env._Player
Wherigo.Player.CompletionCode = Env._CompletionCode
-- some starting_marker with starting location ??


--[[
for k,v in pairs(cartridge) do print(k,v) end
for k,v in pairs(Wherigo.Player.Inventory) do print(k,v) end
for k,v in pairs(Env.__propset) do print(k,v) end
for k,v in pairs(_G) do print(k,v) end
for k,v in pairs(zonePaloucek) do print(k,v) end
]]

-- After runing script, setup media ?
