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

function Wherigo.IsPointInZone(point, zone)
	local num = 0
	local points = zone.Points
	-- Workaround for missing OriginalPoint (Whack a Lackey)
	if not zone.OriginalPoint then
		local lat = 0
		local lon = 0
		for k,v in pairs(points) do
			lat = lat + v.latitude
			lon = lon + v.longitude
			end
		zone.OriginalPoint = Wherigo.ZonePoint( lat/(#points), lon /(#points) )
		end

	num = num + Wherigo._intersect(point, {points[ #points ], points[1]} )
	num = num + Wherigo._intersect(zone.OriginalPoint, {points[ #points ], points[1]} )
	--print(num, points[1])
	for k, pnt in pairs(points) do
		if k > 1 then
			num = num + Wherigo._intersect(point, {points[k-1], points[k]} )
			num = num + Wherigo._intersect(zone.OriginalPoint, {points[k-1], points[k]} )
			--print(num, pnt)
			end
		end
	return (num % 2) == 0
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
	return type(f) == type(s) and f:lower() == s:lower()
	end
	
function Wherigo.Command(text)
	if text == 'SaveClose' then
		Wherigo.LogMessage("Wherigo.Command: SaveClose");
		WIGInternal.Save()
		WIGInternal.Close() -- with prompt ... todo
		exit;
	elseif text == 'DriveTo' then
		Wherigo.LogMessage("Wherigo.Command: DriveTo");
		WIGInternal.DriveTo()
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
		Wherigo.LogMessage("ZInput:GetInput: " .. input.Name .. " -> " .. response)
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

--[[ A direction from one point to another ]]
Wherigo.Bearing = {}
function Wherigo.Bearing.new(value)
	local self = {}
	self.value = value % 360
	
	setmetatable(self, {
		__tostring = function( s )
			return "Bearing (" .. s.value .. "°)"
			end,
		__call = function (s)
			return s.value
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
	
	setmetatable(self, {
		__tostring = function( s )
			return "Distance (" .. s.value .. " meters)"
			end,
		__call = function (s, units)
			return s.GetValue(units)
			end,
		__eq = function( op1, op2 )
			error("Comparing")
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
	local self = {}
	if type(cartridge) == 'table' and not cartridge._classname then
		self = cartridge
		-- table args
		if self.Active == nil then
			self.Active = true
			end
	else
		self = {
			Container = container or nil,
			Cartridge = cartridge or nil,
			Commands = {},
			Active = true,
		}
		end
	self.CurrentBearing = Wherigo.Bearing(0)
	self.CurrentDistance = Wherigo.Distance(0)
		--[[Description = "NoDescription",
		Icon = nil,
		Id = nil,
		Inventory = {}, -- ZObject
		Locked = false,
		Media = nil,
		Name = "NoName",
		ObjectLocation = Wherigo.INVALID_ZONEPOINT,
		Visible = true,]]--
	
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
		Wherigo.LogMessage("Move " .. self.Name .. " to " .. owner.Name)
		self.Container = owner
		end
	
	function self._is_visible()
		if not ((self.Active and self.Visible) or DEBUG) then
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
	if self.Cartridge == nil then
		-- todo
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
	self._state = Wherigo.Zone.NotInRange
	self._inside = false
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
	self._mediacount = -1
	self.AllZObjects = {}
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
	
	Wherigo.Player.Cartridge = self
	
	self._mediacount = 1
	Wherigo.Player.Cartridge = self
	
	function self:RequestSync()
		if self.OnSync then
			self.Onsync(self)
			end
		WIGInternal.save();
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
					print(v.Name, inside, v._inside, v.OriginalPoint, Wherigo.Player.ObjectLocation)
					if inside ~= v._inside then
						update_all = true
						v._inside = inside
						if inside then
							if v._state == 'NotInRange' and v.OnDistant then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Distant")
								v.OnDistant(v) end
							if v._state ~= 'Proximity' and v.OnProximity then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Proximity")
								v.OnProximity(v) end
							if v.OnEnter then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Enter")
								v.OnEnter(v) end
						else
							if v.OnExit then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Exit")
								v.OnExit(v) end
							end
						end
					if inside then
						v.State = 'Inside'
						v._state = v.State
					else
						-- how far?
						v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToZone (Wherigo.Player.ObjectLocation, v)
						print(v.Name, v.CurrentDistance, v.CurrentBearing )
						if v.CurrentDistance() < v.ProximityRange() then
							if v._state == 'NotInRange' and v.OnDistant then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Distant")
								v.OnDistant (v)
								update_all = true
								end
							v.State = 'Proximity'
						elseif v.DistanceRange() < 0 or v.CurrentDistance() < v.DistanceRange() then
							if v._state == 'Inside' and v.OnProximity then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Proximity")
								v.OnProximity(v)
								update_all = true
								end
							v.State = 'Distant'
						else
							if v._state == 'Inside' and v.OnProximity then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Proximity")
								v.OnProximity(v)
								update_all = true
								end
							if (v._state == 'Proximity' or v._state == 'Inside') and v.OnDistant then
								Wherigo.LogMessage("Zone <" .. v.Name .. ">: Distant")
								v.OnDistant(v)
								update_all = true
								end
							v.State = 'NotInRange'
							end
						if v._state ~= v.State then
							Wherigo.LogMessage("Zone <" .. v.Name .. ">: " .. v.State)
							local s = v._state
							v._state = v.State
							local attr = 'On' .. v.State
							local event = rawget(v, attr)
							if event then
								event(v)
								update_all = true
								end
							end
						end
					end
				end
			end
		return update_all
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
	--[[self.Name = 'NoName'
	self.Description = ''
	self.Complete = false
	self.Correct = false]]--
	
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
	self = Wherigo.ZObject(cartridge)
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
			print('Not starting timer: already running.')
			return
			end
		Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: Start")
		if self.OnStart then
			self.OnStart(self)
			end
		if self.Remaining < 0 then
			self.Remaining = self.Duration
			end
		-- call native timer
		self._target = WIGInternal.addTimer(self.Remaining, self.ObjIndex);
		end
	function self:Stop()
		if self._target == nil then
			print('Not stopping timer: not running.')
			return
			end
		Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: Stop")
		-- native timer
		WIGInternal.removeTimer(self.ObjIndex)
		self._target = nil
		if self.onStop then
			self.onStop(self)
			end
		
		end
	function self:Tick()
		Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: Tick")
		if self.Type == 'Interval' then
			self._target = self._target + self.Duration
			now = WIGInternal.getTime()
			if self._target < now then
				self._target = now
				end
			WIGInternal.addTimer(self._target - now, self.ObjIndex)
		else
			-- native timer
			self._target = nil
			self.Remaining = -1
			end
		if self.OnTick then
			self.OnTick(self)
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
function Wherigo.ZTimer._Tick(id)
	local t = cartridge.AllZObjects[id]
	if t._classname == Wherigo.CLASS_ZTIMER then
		t.Tick(t) end
	end

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
	self = Wherigo.ZObject.new(cartridge, container)
	self._classname = Wherigo.CLASS_ZCHARACTER
	--[[self.Name = "Unnamed"
	self.InsideZones = {}
	self.Inventory = {}
	self.ObjectLocation = Wherigo.INVALID_ZONEPOINT]]
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
	Wherigo.LogMessage("ZCommand <" .. t.Name .. ">: " .. event)
	--[[if event == "OnClick" and t.OnClick then
		t.OnClick(t)
	else]]
	t[event](t)
		--end
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
		if v._classname == Wherigo.CLASS_ZONE and (v.Active and v.Visible) then
			if not first then
				locations = locations .. "," end
			locations = locations .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name) .. "\""
				.. ", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
			if v.OriginalPoint then
				locations = locations .. ", \"lat\": " .. v.OriginalPoint.latitude .. ", \"lon\": " .. v.OriginalPoint.longitude
				end
			if v.State == 'Inside' then
				locations = locations .. ", \"distance\": 0, \"bearing\": 0"
			else
				locations = locations .. ", \"distance\": " .. v.CurrentDistance("m") .. ", \"bearing\": " .. v.CurrentBearing("m")
				end
			locations = locations .. Wherigo._addCommands(v)
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
			inventory = inventory .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name)
				.. "\", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
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
			yousee = yousee .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name)
				.. "\", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
				.. Wherigo._getMediaField("media", v.Media)
				.. Wherigo._getMediaField("icon", v.Icon)
				.. Wherigo._addCommands(v)
				.. ", \"id\": \"" .. k .. "\""
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
			tasks = tasks .. "{\"name\": \"" .. WIGInternal.escapeJsonString(v.Name) .. "\""
				.. ", \"description\": \"" .. WIGInternal.escapeJsonString(v.Description) .. "\""
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
