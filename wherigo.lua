package.loaded['Wherigo'] = 1

_VERSION = "Lua 5.1"

Wherigo = {
	INVALID_ZONEPOINT 	= nil,
	
	MAINSCREEN			= "main",
	INVENTORYSCREEN 	= "inventory",
	ITEMSCREEN 			= "you_see",
	LOCATIONSCREEN		= "locations",
	TASKSCREEN			= "tasks",
	DETAILSCREEN 		= "detail",
	
	LOGDEBUG			= 150,
	LOGCARTRIDGE		= 151,
	LOGINFO				= 152,
	LOGWARNING			= 153,
	LOGERROR			= 154,
	
	CLASS_ZONE			= 20,
	CLASS_ZMEDIA		= 21,
	CLASS_ZCARTRIDGE	= 22,
	CLASS_ZCHARACTER	= 23,
	CLASS_ZCOMMAND		= 24,
	CLASS_ZINPUT		= 25,
	CLASS_ZTASK			= 26,
	CLASS_ZITEM			= 27,
	CLASS_ZTIMER		= 28,
	
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
		print("Media: ", media._id)
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
		WIGInternal.MessageBox(text, media, "", "", "0")
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
		return Distance (0), Bearing (0) end
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
	
function Wherigo.TranslatePoint(point, distance, bearing)
	local d = math.rad (distance.GetValue ('nauticalmiles') / 60.)
	local b = math.rad (bearing.value)
	local lat1 = math.rad (point.latitude)
	local lat2 = math.asin (math.sin (lat1) * math.cos (d) + math.cos (lat1) * math.sin (d) * math.cos(b))
	local dlon = math.atan2 (math.sin(b) * math.sin (d) * math.cos (lat1), math.cos (d) - math.sin (lat1) * math.sin (lat2))
	return ZonePoint (math.deg (lat2), point.longitude + math.deg (dlon), point.altitude)
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
	return f.lower() == s.lower()
	end
	
function Wherigo.Command(text)
	if text == 'SaveClose' then
		WIGInternal.Save()
		WIGInternal.Close()
	elseif text == 'DriveTo' then
		WIGInternal.DriveTo()
	elseif text == 'StopSound' then
		WIGInternal.StopSound()
	elseif text == 'Alert' then
		WIGInternal.Alert()
		end
	end

function Wherigo.LogMessage(text, level)
	if type(text) == 'table' then
		level = text.Level
		text = text.Text
		end
	WIGInternal.LogMessage(text, level)
	end

function Wherigo.GetInput(input)
	-- ZInput is dialog to show and returns value from user
	table.insert(Wherigo._GICallbacks, input.OnGetInput)
	--if input.Type == "Text" then
	--	end
	
	WIGInternal.GetInput( input.Type, input.Text) -- think about it
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
	
	function self.GetValue(units)
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
			return self.GetValue(units)
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
	function self:MoveTo(owner)
		self.Container = owner
		end
	function self._is_visible()
		if not (self.Active and self.Visible) then
			return false
			end
		if self.Container == nil then
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
	
	-- initialization
	if cartridge == nil then
		-- todo
		self.ObjIndex = -1
		return self
		end
	if Wherigo.ZCartridge._store ~= nil then
		--print(debug.traceback())
		self.ObjIndex = # cartridge.AllZObjects + 1;
		table.insert(cartridge.AllZObjects, self)
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
	local self = Wherigo.ZObject.new(cartridge)
	self._classname = Wherigo.CLASS_ZONE
	self.OriginalPoint = Wherigo.INVALID_ZONEPOINT
	
	self._state = Wherigo.Zone.NotInRange
	self.Active = false
	self.Visible = false
	self._inside = false
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
	self._classname = Wherigo.CLASS_ZCARTRIDGE
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
	
	function self._update(position, t)
		for k,v in pairs(self.AllZObjects) do
			if v._classname == Wherigo.CLASS_ZTIMER and v._target ~= nil then
				v.Remaining = v._target - t
				end
			end
		local update_all = false
		if not position then
			return false end
		Wherigo.Player.ObjectLocation = position
		for k,v in pairs(self.AllZObjects) do
			if v.Active then
				if (v._classname == Wherigo.CLASS_ZITEM and v.Container ~= Wherigo.Player)
						or v._classname == Wherigo.CLASS_ZCHARACTER then
					local pos = v._get_pos()
					if pos then
						v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToPoint(Wherigo.Player.ObjectLocation, pos)
						end
				elseif v._classname == Wherigo.CLASS_ZONE then
					-- something with Active and _active ???
					local inside = Wherigo.IsPointInZone (Wherigo.Player.ObjectLocation, v)
					if inside ~= v._inside then
						update_all = true
						v._inside = inside
						if inside then
							if v._state == 'NotInRange' and v.OnDistant then
								v.OnDistant() end
							if v._state ~= 'Proximity' and v.OnProximity then
								v.OnProximity() end
							if v.OnDistant then
								v.OnEnter() end
						else
							if v.OnExit then
								v.OnExit() end
							end
						end
					if inside then
						v.State = 'Inside'
						v._state = v.State
					else
						-- how far?
						v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToZone (Wherigo.Player.ObjectLocation, v)
						if v.CurrentDistance() < v.ProximityRange() then
							if v._state == 'NotInRange' and v.OnDistant then
								v.OnDistant ()
								update_all = true
								end
							v.State = 'Proximity'
						elseif v.DistanceRange() < 0 or v.CurrentDistance() < v.DistanceRange() then
							if v._state == 'Inside' and v.OnProximity then
								v.OnProximity()
								update_all = true
								end
							v.State = 'Distant'
						else
							if v._state == 'Inside' and v.OnProximity then
								v.OnProximity()
								update_all = true
								end
							if (v._state == 'Proximity' or v._state == 'Inside') and v.OnDistant then
								v.OnDistant()
								update_all = true
								end
							v.State = 'NotInRange'
							end
						if v._state ~= v.State then
							local s = v._state
							v._state = v.State
							local attr = 'On' .. v.State
							local event = rawget(v, attr)
							if event then
								event()
								update_all = true
								end
							end
						end
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
	self._classname = Wherigo.CLASS_ZMEDIA
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
	setmetatable(self, {
		__tostring  = function(s)
			return "<ZMedia Id=" .. s._id .. ">"
			end
	}) 

	return self
	end
setmetatable(Wherigo.ZMedia, {
	__call = function(s, cartridge)
		return Wherigo.ZMedia.new(cartridge)
		end
	}) 

Wherigo.ZItem = {}
function Wherigo.ZItem.new( cartridge, container )
	if type(cartridge) == 'table' and not cartridge._classname  then
		container = cartridge.Container
		cartridge = cartridge.Cartridge
		end
	local self = Wherigo.ZObject(cartridge, container)
	self._classname = Wherigo.CLASS_ZITEM
	self._target = nil
	
	setmetatable(self, {
		__tostring = function( s )
			return "ZItem (" .. s.Name .. ")"
			end,
	})
	
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
	self._classname = Wherigo.CLASS_ZTASK
	self.Name = 'NoName'
	self.Description = ''
	self.Complete = false
	self.Correct = false
	
	setmetatable(self, {
		__tostring = function( s )
			return "ZTask (" .. s.Name .. ")"
			end,
	})
	-- events OnClick, SetCorrectState, OnSetComplete, OnSetActive
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
	self._classname = Wherigo.CLASS_ZTIMER
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
	
	setmetatable(self, {
		__tostring = function( s )
			return "ZTimer (" .. s.Name .. ")"
			end,
	})
	
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
	self._classname = Wherigo.CLASS_ZINPUT
	--[[
	OnGetInput event
	]]
	
	setmetatable(self, {
		__tostring = function( s )
			return "ZInput (" .. s.Name .. ")"
			end,
	})
	
	return self
	end
setmetatable(Wherigo.ZInput, {
	__call = function(s, cartridge)
		return Wherigo.ZInput.new(cartridge)
		end
	})

Wherigo.ZCharacter = {}
function Wherigo.ZCharacter.new( cartridge, container )
	if type(cartridge) == 'table' and not cartridge._classname  then
		container = cartridge.Container
		cartridge = cartridge.Cartridge
		end
	self = Wherigo.ZObject.new(cartridge)
	self._classname = Wherigo.CLASS_ZCHARACTER
	self.Name = "Unnamed"
	self.InsideZones = {}
	self.Inventory = {}
	self.ObjectLocation = Wherigo.INVALID_ZONEPOINT
	self.PositionAccuracy = Wherigo.Distance(5)
	
	setmetatable(self, {
		__tostring = function( s )
			return "ZCharacter (" .. s.Name .. ")"
			end,
	})
	
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

Wherigo._callback = function(event, id)
	local t = cartridge.AllZObjects[id]
	if event == "OnClick" and t.OnClick then
		t.OnClick(t)
		end
	--cartridge.AllZObjects[id][event]()
	end

Wherigo._getMediaField = function(field, t)
	if t then
		return ", \"" .. field .. "\": \"" .. Env.CartFolder .. t._id .. "." .. t.Resources[1].Type .. "\""
	else
		return "" end
	end


Wherigo._getUI = function()
	--[[for k,v in pairs(cartridge.AllZObjects) do
		print(v)
		if v._classname == Wherigo.CLASS_ZMEDIA and v.Resources then
			print(v.Resources[1].Type, v.Resources[1].Filename) end
		end]]
	return "{ \"locations\": " .. Wherigo._getLocations() .. ", "
		.. "\"youSee\": " .. Wherigo._getYouSee() .. ", "
		.. "\"inventory\": " .. Wherigo._getInventory() .. ", "
		.. "\"tasks\": " .. Wherigo._getTasks() .. "}"
	end

Wherigo._getLocations = function()
	local locations = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if v._classname == Wherigo.CLASS_ZONE and v.Active and v.Visible then
			if not first then
				locations = locations .. "," end
			locations = locations .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name) .. "\""
				.. ", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
				.. ", \"distance\": " .. v.CurrentDistance("m") .. "}"
			first = false
			end
		end
	return locations .. "]"
end

Wherigo._getInventory = function()
	local inventory = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if v.Active and v.Visible and v.Container == Wherigo.Player then
			if not first then
				inventory = inventory .. "," end
			inventory = inventory .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name)
				.. "\", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
			inventory = inventory .. Wherigo._getMediaField("media", v.Media)
			inventory = inventory .. Wherigo._getMediaField("icon", v.Icon)
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
			yousee = yousee .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name)
				.. "\", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
			yousee = yousee .. Wherigo._getMediaField("media", v.Media)
			yousee = yousee .. Wherigo._getMediaField("icon", v.Icon)
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
			tasks = tasks .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name) .. "\""
				.. ", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
				.. ", \"id\": \"" .. k .. "\""
			tasks = tasks .. Wherigo._getMediaField("media", v.Media)
			tasks = tasks .. Wherigo._getMediaField("icon", v.Icon)
			if v.OnClick then
				tasks = tasks .. ", \"onclick\": true"
				end
			tasks = tasks .. "}"
			first = false
			end
		end
	return tasks .. "]"
end
