--- Wherigo Library, backward compatible with Wherigo Library by Groundspeak
--   @module Wherigo
--   @author Jakub Jelen <a href="jakuje@gmail.com">jakuje@gmail.com</a>
--   @copyright 2012 - 2013
-- 

--- Obfuscation to ignore require("Wherigo") in user scripts
--   this adds key Wherigo to list of loaded modules and so lua engine
--   will not look for library all over the filesystem
package.loaded['Wherigo'] = 1

-- Variable to show more than normal player should view (hidden zones)
DEBUG = false

Wherigo = {
	-- ZonePoint is not set
	INVALID_ZONEPOINT 	= nil,
	
	-- Constants for ShowScreen function
	MAINSCREEN			= "main",
	INVENTORYSCREEN 	= "inventory",
	ITEMSCREEN 			= "youSee",
	LOCATIONSCREEN		= "locations",
	TASKSCREEN			= "tasks",
	DETAILSCREEN 		= "detail",
	
	-- Constants for LogMessage function
	LOGDEBUG			= 150,
	LOGCARTRIDGE		= 151,
	LOGINFO				= 152,
	LOGWARNING			= 153,
	LOGERROR			= 154,
	
	-- Internal constants to determine object name
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
	CLASS_ZRECIPROCALCOMMAND = "ZReciprocalCommand",
	CLASS_ZOBJECT		= "ZObject",
	
	-- internal tables to store callbacks from MessageBox and GetInput
	_MBCallbacks = {},
	_GICallbacks = {},
	_CMDWithCallbacks = {}
	}

--- Show message to user
--   accepts table param or multiple parameters as below.
--   Params table: <ul>
--   <li> Text 		string message to show (required)
--   <li> Media		ZMedia image to show with it
--   <li> Buttons		Table with text to show on buttons
--   <li> Callback	Function to call after user pushes on of the buttons
--   </ul>
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
--- Receives users response and calls desired callback. Called only if
--   callback was set. Internal usage only!
-- 
--   @param	action	Button1 or Button2 or nil depending on user choice
function Wherigo._MessageBoxResponse(action)
	if # Wherigo._MBCallbacks > 0 then
		Wherigo.LogMessage("MessageBox Callback: [" .. action .. "]")
		callback = table.remove(Wherigo._MBCallbacks)
		callback(action)
	else
		error("Recieved MessageBox response to no request")
		end
	end
	
--- Shows series of messages to user, one after another. Internal using 
--   MessageBox. For more details @see MessageBox
-- 
--   @param t	Table of tables with keys "Text" and "Media" to be shown
function Wherigo.Dialog(t)
	-- change to correspond with Groundspeak
	local message
	if type(t) ~= 'table' then
		error("Dialog expected table")
	elseif type(t[1]) ~= 'table' then
		message = {}
		message.Text = t.Text
		message.Media = t.Media
	else
		message = t[1]
		end
	
	-- ignore functions ...
	
	if not message then
		return
		end
	table.remove(t, 1)
	if #t > 0 then
		message.Callback = function(action)
			if action then
				Wherigo.LogMessage("Dialog response")
				Wherigo.Dialog(t)
				end
			end
	else
		message.Callback = nil
		end
	Wherigo.MessageBox(message);
	end

--- Request to play user some audio. Sends request to user interface what
--   handles it. If it is long, can be stopped by calling Command("StopSound")
-- 
--   @param	Media	ZMedia object containing audio to play
function Wherigo.PlayAudio(Media)
	WIGInternal.PlayAudio(Media._id)
	end
	
--- Shows status text somewhere. Not used and not well documented
--
--   @param Text	What should be shown to user
function Wherigo.ShowStatusText(Text)
	-- for PPC devices only?
	WIGInternal.ShowStatusText(Text)
	end

--- Calculates distance from given point to nearest point of given zone
--   
--   @param		point	ZonePoint object as a starting location
--   @param 	zone	Zone object as a destination
--   @return	Distance (object) to nearest point of zone
--   @return	Bearing (object) to nearest point of zone
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

--- Calculates distance from given point to nearest point on segment of zone
--   defined by two points (p1, p2)
--
--   @param		point	ZonePoint object as a starting location
--   @param		p1		ZonePoint, first point of segment
--   @param		p2		ZonePoint, second point of segment
--   @return	Distance (object) to nearest point of segment
--   @return	Bearing (object) to nearest point of segment
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
	local intersect = Wherigo.TranslatePoint (p1, Wherigo.Distance (dat * 60, 'nauticalmiles'), bs)
	return Wherigo.VectorToPoint (point, intersect)
	end

--- Unknown purpose
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

--- Determines whether is given point in given zone using Minimal Bounding 
--   Box algorithm and then with Cross Count algorithm
--
--   @param		point	ZonePoint object
--   @param		zone	Zone object
--   @return 	True if is point in zone
function Wherigo.IsPointInZone(point, zone)
	-- fisrt go through Bounging Box
	if( zone._xmin == nil) then zone._calculateBoundingBox() end
	if( zone._xmin == nil)  then return false end -- no valid points
	--print(zone._xmin, point.longitude, zone._xmax)
	--print(zone._ymin, point.latitude, zone._ymax)
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

--- Calculate new position of point, which is translated by given distance
--   and with given bearing
--
--   @param		point		ZonePoint object as a starting point
--   @param		distance	Distance object
--   @param		bearing		Bearing object or number to determine direction
--   @return 	ZonePoint object with new location
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

--- Calculate distance and bearing from one point to another
-- 
--   @param		p1	Starting ZonePoint
--   @param		p2	Destination ZonePoint
--   @return	Distance object
--   @return	Bearing object
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

--- Compare two strings ignoring case
--
--   @param		f	First string
--   @param		s	Second string
--   @return	True if they equals
function Wherigo.NoCaseEquals(f, s)
	return type(f) == type(s) and f:lower() == s:lower()
	end

--- Sends some command to engine<br>
--    Possible values:
--    <ul>
--		<li>SaveClose	- Saves cartridges and prompt user to quit
--		<li>DriveTo		- This should start Turn-by-turn navigation, but it is not used
--		<li>StopSound	- Stops playing sound in user interface
--		<li>Alert		- Beep. Used on Garmins, which can't play sound
--    </ul>
--
--   @param text	Command
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

--- Write message into logfile for opened cartridge
--   params can be table
--
--   @param	Text	Message to log
--   @param	Level	Level of message
function Wherigo.LogMessage(Text, Level)
	if type(Text) == 'table' then
		Level = Text.Level
		Text = Text.Text
		end
	WIGInternal.LogMessage(Text--[[, Level]])
	end

--- Request user to fill in input. Appearance depends on ZInput object
--
--   @param	input	ZInput object containing data about input appearance
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
--- Callback of GetInput. Internal usage only!
--   This is called for every GetInput
-- 
--   @param	response	User's response (selected button or written string)
function Wherigo._GetInputResponse( response )
	if # Wherigo._GICallbacks > 0 then
		local input = table.remove(Wherigo._GICallbacks)
		Wherigo.LogMessage("ZInput:GetInput: " .. input.Name .. ": OnGetInput [" .. response .. "]")
		input.OnGetInput(input, response)
	else
		error("Recieved GetInput response to no request")
		end
	end

--- Sends request to user interface to show screen
--
--   @param	screen	Screen name (see constants)
--   @param item	For 'DETAILSCREEN' particular ZObject
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

--- Conversion function from Distance or Bearing object to number
--   used in metamethods to arithmetic and comparisons
--
--   @param		arg		Number or object to convert
--   @return	Number representing Distance in meters or bearing in degrees
function Wherigo.__tonumber(arg)
	if type(arg) == "table" then
		arg = arg.value
		end
	return arg
	end


--[[
for k,v in pairs(cartridge) do print(k,v) end
for k,v in pairs(Wherigo.Player.Inventory) do print(k,v) end
for k,v in pairs(Env.__propset) do print(k,v) end
for k,v in pairs(_G) do print(k,v) end
for k,v in pairs(zonePaloucek) do print(k,v) end
for k,v in pairs(itemDum1.Commands.Akce1) do print(k,v) end

for k,v in pairs(cartridge.AllZObjects) do print(k,v, v.Active, v.Visible) end
for k,v in pairs(cartridge.AllZObjects) do print(k,v, v.ObjIndex, cartridge.AllZObjects[k]) end
]]

-- After runing script, setup media ?

--- Execute user command or click event on UI item. OnClick is simply executed,
--   other events On* of commands must be handled with care of command type.
--   Internal use only.
--
--   @param event	Event name in Commands table, or Click for OnClick event
--   @param id		Global id in AllZObjects table
Wherigo._callback = function(event, id)
	local t = cartridge.AllZObjects[id]
	if event == "Click" then
		if t.OnClick then
			Wherigo.LogMessage(t._classname .. " <" .. t.Name .. "> ZCommand: On" .. event .. " START")
			t["On" .. event](t)
			Wherigo.LogMessage(t._classname .. " <" .. t.Name .. "> ZCommand: On" .. event .. " END__")
			end
	else
		if t then
			local command = tonumber(event) or event
			local c = t.Commands[command]
			if not c.CmdWith then
				if t["On" .. event] then
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. "> ZCommand: On" .. event .. " START")
					t["On" .. event](t)
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. "> ZCommand: On" .. event .. " END__")
				else
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. "> ZCommand: On" .. event .. " [no script]")
					end
			else
				--local list = {}
				local choices = ""
				if c.WorksWithAll then
					for k,v in pairs(cartridge.AllZObjects) do
						if (v.Visible and v.Container == Wherigo.Player) or v._is_visible() then
							--table.insert(list, v);
							if # choices ~= 0 then
								choices = choices .. ";"
								end
							choices = choices .. v.Name
							end
						end
				elseif c.WorksWithList then
					for k,v in pairs(c.WorksWithList) do
						if (v.Visible and v.Container == Wherigo.Player) or v._is_visible() then
							--table.insert(list, v);
							if # choices ~= 0 then
								choices = choices .. ";"
								end
							choices = choices .. v.Name
							end
						end
				else
					Wherigo.LogMessage(c.Text .. " Works with nothing??")
					end
				if # choices == 0 then
					WIGInternal.Dialog( c.EmptyTargetListText, "")
					return
					end
				Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">: CommandWith prompt")
				table.insert(Wherigo._GICallbacks, Wherigo._Internal)
				table.insert(Wherigo._CMDWithCallbacks, t["On" .. event])
				WIGInternal.GetInput("MultipleChoice", "Choose what to command with", choices, "");
				end
			end
		end
	end
--- Virtual object to execute command with other item, same way as GetInput.
--   Internaly substitutes ZInput object.
-- 
--   @class table
--   @name Wherigo._Internal
Wherigo._Internal = { Name = "CMDWith (internal)"}
Wherigo._Internal.OnGetInput = function(self, choice)
	Wherigo.LogMessage("Choice CMDwith: " .. choice)
	if # Wherigo._CMDWithCallbacks > 0 then
		local event = table.remove(Wherigo._CMDWithCallbacks)
		for k,v in pairs(cartridge.AllZObjects) do
			if ((v.Visible and v.Container == Wherigo.Player) or v._is_visible()) and v.Name == choice then
				Wherigo.LogMessage("ZCommand <??>: ?? with [" .. v.Name .. "] START")
				event(nil, v);
				Wherigo.LogMessage("ZCommand <??>: ?? with [" .. v.Name .. "] END__")
				return
				end
			end
		end
	end

--- Get field with media path in JSON notation for UI. Internal usa only.
--
--   @param field	String "media" or "icon" used as index in JSON
--   @param t		Table value to chech and add it exists
--   @return String containing JSON notation of field or empty string if <i>t</i> is nil
Wherigo._getMediaField = function(field, t)
	if t then
		return ", \"" .. field .. "\": \"" .. --[[Env.CartFolder ..]] t._id .. "." .. t.Resources[1].Type .. "\""
	else
		return "" end
	end

--- Get Commands field with array of enabled commands for current object in JSON notation.
--   Internal use only!
--
--   @param item	ZObject to get commands for
--   @return 		String containing JSON notation of commands field
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

--- Convert boolean value to string for JSON notation. Internal use only!
--   @param b	Boolean value
--   @return 	String value containing true or false
Wherigo._bool2str = function( b )
	if b then return "true"
	else return "false" end
	end

--- Escape string to put in JSON structure. Just proxy to ignore nil values.
--   Internal use only!
--   @param str	String to escape
--   @return Escaped string
Wherigo._toJSON = function(str)
	if str ~= nil then
		return WIGInternal.escapeJsonString(str)
	else
		return ""
		end
	end

--- Get JSON fields to send to UI, containing all 4 sections, without brackets around,
--   so C++ can add more fields. Internal use only!
--   @return String containing JSON notation of UI data
Wherigo._getUI = function()
	return --"{" ..
		"\"locations\": " .. Wherigo._getLocations() .. ", "
		.. "\"youSee\": " .. Wherigo._getYouSee() .. ", "
		.. "\"inventory\": " .. Wherigo._getInventory() .. ", "
		.. "\"tasks\": " .. Wherigo._getTasks() -- .. "}"
		-- it is just without brackets around, so c++ can add more fields
	end

--- Get Locations data in JSON to be send to UI. Internal use only!
--   @return String containing JSON
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

--- Get Inventory data in JSON to be send to UI. Internal use only!
--   @return String containing JSON
Wherigo._getInventory = function()
	local inventory = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if ( v.Visible or DEBUG) and v.Container == Wherigo.Player then
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

--- Get YouSee data in JSON to be send to UI. Internal use only!
--   @return String containing JSON
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

--- Get Tasks data in JSON to be send to UI. Internal use only!
--   @return String containing JSON
Wherigo._getTasks = function()
	local tasks = "["
	local first = true
	for k,v in pairs(cartridge.AllZObjects) do
		if v._classname == Wherigo.CLASS_ZTASK and v.Visible then
			if not first then
				tasks = tasks .. "," end
			tasks = tasks .. "{\"name\": \"" .. Wherigo._toJSON(v.Name) .. "\""
				.. ", \"description\": \"" .. Wherigo._toJSON(v.Description) .. "\""
				.. Wherigo._getMediaField("media", v.Media)
				.. Wherigo._getMediaField("icon", v.Icon)
				.. Wherigo._addCommands(v)
				.. ", \"id\": \"" .. k .. "\""
				.. ", \"sort\": \"" .. v.SortOrder .. "\""
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




--- Object representing a bearing in degrees.
-- @type Wherigo.Bearing
Wherigo.Bearing = {}
--- Metatable for Bearing objects. Implements arithmetic, call and tostring 
--   as required by cartridges
-- @class table
Wherigo.Bearing.metatable = {
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
--- Bearing object constructor. Number is automatically normalized to interval
--   0 - 360 degrees
--
--   @param value Numeric value representing bearing in degrees
--   @return Bearing instance
function Wherigo.Bearing.new(value)
	local self = { _classname = Wherigo.CLASS_BEARING}
	if type(value) == 'number' then
		self.value = value % 360
	else
		self.value = 0
		end
	
	setmetatable(self, Wherigo.Bearing.metatable)

	return self;
	end
setmetatable(Wherigo.Bearing, {
	__call = function( s, value)
		return Wherigo.Bearing.new(value)
		end,
	})



--- Object representing distance in meters.
-- @type Wherigo.Distance
Wherigo.Distance = {}
--- Metatable for Distance objects. Implements arithmetic, comparison, call
--   and tostring as required by cartridges
Wherigo.Distance.metatable = {
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
--- Distance object constructor. Represent distance in meters
-- 
--   @param value Numeric value of distance (required)
--   @param units String representation of units in which is value set for conversion, default "meters"
--   @return Distance instance
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
	
	--- Conversion function to get distance in other units
	-- @name GetValue
	-- @class function
	-- 
	-- @param units String representation of units in which you want the result, default "meters"
	-- @return Numeric representation of distance in required units
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
	
	setmetatable(self, Wherigo.Distance.metatable)
	
	return self
	end
setmetatable(Wherigo.Distance, {
	__call = function (s, value, units)
		return Wherigo.Distance.new(value, units)
		end
	})



--- Object representing ZCommand of ZObject.
-- @type Wherigo.ZCommand
Wherigo.ZCommand = {}
--- Metatable for ZCommand objects. Implements index, newindex to watch 
--   Enabled property and tostring
Wherigo.ZCommand.metatable = {
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
			return
			end
		rawset(t, key, value)
		end,
}
--- ZCommand object constructor. Sets allowed combination of parameters
-- 
--   @param table Parameters of command to set
--   @return ZCommand object
function Wherigo.ZCommand.new(table)
	table = table or {}
	-- ReciprocatedCmds
	-- EmptyTargetListText
	local self = {
		Text = table.Text or '',
		CmdWith = table.CmdWith or false,
			EmptyTargetListText = table.EmptyTargetListText or 'No target visible',
			MakeReciprocal = true,
			WorksWithAll = false,
			WorksWithList = table.WorksWithList or false, -- Zcharacter, ZItem
		Custom = true, -- doesn't matter
		ReciprocatedCmds = {},
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
	setmetatable(self, Wherigo.ZCommand.metatable)
	return self;
	end
--- Check membership of given object to class ZCommand
-- @param object Some object
-- @return True if object is a member of class
function Wherigo.ZCommand:made( object )
	return (object._classname == Wherigo.CLASS_ZCOMMAND)
	end
setmetatable(Wherigo.ZCommand, {
	__call = function(s, table)
		return Wherigo.ZCommand.new(table)
		end
	})



--- ZReciprocalCommand object
-- @type Wherigo.ZReciprocalCommand
Wherigo.ZReciprocalCommand = {}
--- Metatable for ZReciprocalCommand objects. Implements tostring
Wherigo.ZReciprocalCommand.metatable = {
	__tostring = function(s)
		return "a ZReciprocalCommand instance"
		end,
}
--- ZReciprocalCommand object constructor. Sets parameters from arguments.
--   Not used in runtime.
-- 
--   @param table Parameters of command to set
--   @return ZReciprocalCommand object
function Wherigo.ZReciprocalCommand.new(table)
	table = table or {}
	local self = {}
	setmetatable(self, Wherigo.ZReciprocalCommand.metatable)
	return self;
	end
--- Check membership of given object to class ZReciprocalCommand
-- @param object Some object
-- @return True if object is a member of class
function Wherigo.ZReciprocalCommand:made( object )
	return (object._classname == Wherigo.CLASS_ZRECIPROCALCOMMAND)
	end
setmetatable(Wherigo.ZReciprocalCommand, {
	__call = function(s, table)
		return Wherigo.ZReciprocalCommand.new(table)
		end
	})



--- Base object for all next Z* objects. Implements all common
-- @type Wherigo.ZObject
Wherigo.ZObject = {} 
--- Metatable for ZObject objects. Implements index and newindex to keep
--   a track of desired properties and to invoke desired actions
Wherigo.ZObject.metatable = {
	__index = function(t, key)
		if key == 'Active' then
			return t._active
		elseif key == 'CommandsArray' then
			if t._classname == Wherigo.CLASS_ZCHARACTER or t._classname == Wherigo.CLASS_ZONE or t._classname == Wherigo.CLASS_ZITEM then 
				local arr = {}
				local index = 1
				for i,v in pairs(t.Commands) do
					v.Keyword = i
					v.Owner = t
					v.Index = index
					index = index + 1
					table.insert(arr, v)
					end
				return arr -- runtime doesn't work with CommandsArray. Only export!
			else
				return nil
				end
		elseif key == 'ObjectLocation' then
			return t._get_pos(false) -- do not export. Only for ... some cartridges ... like default value
		elseif key == 'ClosestPoint' then
			if t._classname == Wherigo.CLASS_ZONE then
				return Wherigo._INVALID_ZONEPOINT
			else
				return nil
				end
		elseif key == 'Inventory' then
			local arr = {}
			for k,v in pairs(cartridge.AllZObjects) do
				if (v.Visible or DEBUG) and v.Container == t then
					table.insert(arr, v)
					end
				end
			return arr -- runtime doesn't work with Inventory. For game objects and export
		elseif key == 'CorrectState' and t._classname == Wherigo.CLASS_ZTASK then
			return t._correct
		elseif key == 'Complete' and (t._classname == Wherigo.CLASS_ZTASK or t._classname == Wherigo.CLASS_ZCARTRIDGE) then
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
						local lat = 0
						local lon = 0
						for k,v in pairs(t.Points) do
							lat = lat + v.latitude
							lon = lon + v.longitude
							end
						t.OriginalPoint = Wherigo.ZonePoint( lat/(#t.Points), lon /(#t.Points) )
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
		elseif key == 'Inventory' or key == 'ClosestPoint' then
			-- ignore ...
			return
		elseif key == 'CommandsArray' then
			-- restore Commands from SaveGame
			for i,v in ipairs(value) do
				v.Index = i
				t.Commands[v.Keyword] = v
				end
			return
		elseif key == 'Complete' and (t._classname == Wherigo.CLASS_ZTASK or t._classname == Wherigo.CLASS_ZCARTRIDGE) then
			if value ~= t._complete then
				t._complete = value
				if t._classname == Wherigo.CLASS_ZCARTRIDGE and value then
					WIGInternal.CartridgeEvent("complete");
					end
				Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">.Complete = " .. Wherigo._bool2str(value))
				if t.OnSetComplete then
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">: START OnSetComplete")
					t.OnSetComplete(t)
					Wherigo.LogMessage(t._classname .. " <" .. t.Name .. ">: END__ OnSetComplete")
					end
				end
			return
		elseif t._classname == Wherigo.CLASS_ZTASK and key == 'CorrectState' then
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
			end
		rawset(t, key, value)
		end
}
--- ZObject constructor. Sets default values and parameters of all objects.
--   Also can accept table argument with all values to set
-- 
--   @param cartridge ZCartridge object of global cartridge
--   @param container Default location of object. Can be moved later by calling Wherigo.ZObject.MoveTo function
--   @return ZObject
function Wherigo.ZObject.new(cartridge, container )
	local self = {}
	if type(cartridge) == 'table' and not cartridge._classname then
		self = cartridge
		-- table args
		if self.Active ~= nil then
			self._active = self.Active
			self.Active = nil
		--elseif 
		--	self._active = true
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
		if self.Container == nil  then
			self.Container = false
			end
		if self.Media == nil  then
			self.Media = false
			end
		if self.Icon == nil  then
			self.Icon = false
			end
	else
		self = {
			Container = container or false,
			Cartridge = cartridge or nil,
			--_active = true,
			Media = false,
			Icon = false,
		}
		end
	self.Name = self.Name or "(NoName)"
	self.Description = self.Description or ""
	self.Commands = self.Commands or {}
	self.ObjectLocation = self.ObjectLocation or 0
	self._classname = Wherigo.CLASS_ZOBJECT
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
	
	--- Check weather obj is contained in self container (recursive search)
	--   Special handling for Player and detecting if is in zone.
	--
	-- @name Contains
	-- @class function
	-- @param obj Object to check 
	-- @return True if self contains obj
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
	--- Move self object to another container or to nil
	--
	-- @name MoveTo
	-- @class function
	-- @param owner Destination container
	function self:MoveTo(owner)
		if owner ~= nil then
			Wherigo.LogMessage("Move " .. self.Name .. " to " .. owner.Name)
		else
			Wherigo.LogMessage("Move " .. self.Name .. " to (nowhere)")
			end
		self.Container = owner
		end
	
	--- Checks if self object is visible to player. Internal use only!
	--
	-- @name _is_visible
	-- @class function
	-- @return True if is object visible
	function self._is_visible()
		if not ( self.Visible or DEBUG) then
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
	
	--- Return position of object. Recurs into Container property. Internal use only!
	--
	-- @name _get_pos
	-- @class function
	-- @return ZonePoint object or nil if is position of object undefined
	function self._get_pos (exists)
		if exists == nil then
			exists = true
			end
		if self._classname == Wherigo.CLASS_ZONE then
			return self.OriginalPoint end
		if self._classname ~= Wherigo.CLASS_ZCHARACTER and self._classname ~= Wherigo.CLASS_ZITEM then
			return nil end -- ignore tasks
		if not exists or not self.ObjectLocation then
			if self.Container then
				return self.Container._get_pos ()
				end
			end
		if exists then
			return self.ObjectLocation
		else
			return nil
			end
		end
	
	setmetatable(self, Wherigo.ZObject.metatable)
	
	-- initialization
	if self.Cartridge == nil then
		-- we don't have cartridge, so it is Player
		-- or Cartridge
		self.ObjIndex = -1
		return self
		end
	if Wherigo.ZCartridge._store ~= nil then
		--print(debug.traceback())
		self.ObjIndex = # self.Cartridge.AllZObjects + 1
		table.insert(self.Cartridge.AllZObjects, self)
		end
	return self
	end
--- Check membership of given object to class ZObject
-- @param object Some object to test
-- @return True if object is a member of class
function Wherigo.ZObject:made( object )
	return object._classname == Wherigo.CLASS_ZOBJECT
	end
setmetatable(Wherigo.ZObject, {
	__call = function(s, cartridge, container)
		return Wherigo.ZObject.new(cartridge, container)
		end
})

--- ZonePoint object representing geographical point on sphere
-- @type Wherigo.ZonePoint
Wherigo.ZonePoint = {} 
--- Metatable for ZonePoint objects. Implements tostring as required by cartridges
Wherigo.ZonePoint.metatable = {
	__tostring = function(s)
		return "a ZonePoint instance"
		end
}
--- ZonePoint constructor. Creates new ZonePoint object defined by geographical
--   coordinates and altitude.
--
--   @param	lat	Latitude
--   @param lon	Longitude
--   @param alt	Altitude
--   @return 	ZonePoint object
function Wherigo.ZonePoint.new(lat, lon, alt)
	local self = { _classname = Wherigo.CLASS_ZONEPOINT}
	self.latitude = lat
	self.longitude = lon
	if type(alt) ~= "table" then
		self.altitude = Wherigo.Distance(alt)
	else
		self.altitude = alt
		end
	
	setmetatable(self, Wherigo.ZonePoint.metatable)
	return self
	end
--- Check membership of given object to class ZonePoint
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZonePoint:made( object )
	return (object._classname == Wherigo.CLASS_ZONEPOINT)
	end
setmetatable(Wherigo.ZonePoint, {
	__call = function( s, lat, lon, alt)
		return Wherigo.ZonePoint.new(lat, lon, alt)
		end
	}) 



--- Zone object extends ZObject. Location, defined with 3 or more ZonePoint.
-- @type Wherigo.Zone
Wherigo.Zone = {}
--- Metatable for ZonePoint objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.Zone.metatable = {
	__tostring = function(s)
		return "a Zone instance"
		end
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.Zone.metatable[k] = v end
--- Zone constructor, extend ZObject. Creates new Zone object.
--
--   @param cartridge	global cartridge object
--   @return 	Zone object
function Wherigo.Zone.new(cartridge)
	local self = Wherigo.ZObject.new(cartridge)
	self._classname = Wherigo.CLASS_ZONE
	table.insert(self.Cartridge.AllZones, self)
	self._state = 'NotInRange'
	self.State = self._state
	self._inside = false
	self.Inside = self._inside
	self.CurrentBearing = Wherigo.Bearing(0)
	self.CurrentDistance = Wherigo.Distance(0)
	self.Points = {}
	if self.Active == nil then
		self._active = true
		end -- default value only for Zone!
	
	self.ShowObjects = self.ShowObjects or "OnEnter"
	self.DistanceRange = self.DistanceRange or Wherigo.Distance(-1, "feet")
	self.ProximityRange = self.ProximityRange or Wherigo.Distance(60, "meters")
	
	--[[
	self.OriginalPoint = Wherigo.INVALID_ZONEPOINT
	
	self.Active = false
	self.Visible = false
	self.Name = "NoName"
	
	
		events OnDistant, OnEnter, OnNotInRange, OnExit, OnProximity, OnSetActive
	]]
	
	--- Computes minimum bounding rectangle of this zone. Internal use only!
	--
	-- @class function
	-- @name Wherigo.Zone._calculateBoundingBox
	function self._calculateBoundingBox()
		if self.Points[1] ~= Wherigo.INVALID_ZONEPOINT then
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
			end
		end
	
	setmetatable(self, Wherigo.Zone.metatable) 
	return self
	end
--- Check membership of given object to class Zone
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.Zone:made( object )
	return (object._classname == Wherigo.CLASS_ZONE)
	end
--- Update zone state depending on location update. Recalculate distance
--   and change state if required
--
--   @param v	Zone object
--   @return 	True if changed. Unused.
function Wherigo.Zone._update( v )
	local inside = Wherigo.IsPointInZone (Wherigo.Player.ObjectLocation, v)
	--print(v.Name, inside, v._inside, v.OriginalPoint, Wherigo.Player.ObjectLocation)
	local comfortZone = 7
	if Wherigo.Player.PositionAccuracy() < 10 then
		comfortZone = 4
		end -- handle jitter and unexpected leaving zone
	if not inside then
		-- how far?
		if # v.Points == 0 or v.Points[1] == Wherigo.INVALID_ZONEPOINT then
			return update_all end
		v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToZone (Wherigo.Player.ObjectLocation, v)
		--[[Wherigo.LogMessage(v.Name .. ": d:" .. tostring(v.CurrentDistance()) .. ", p:" ..
			tostring(v.ProximityRange()) .. ", d:" .. tostring(v.DistanceRange() ))]]
		end
	if inside ~= v._inside then
		update_all = true
		if inside then -- we go in
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
		elseif v.CurrentDistance() > comfortZone then -- leave it only if we are more than 15 meters from zone
			Wherigo.Player._removeFromZone(v)
			if v.OnExit then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onExit")
				v.OnExit(v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onExit")
				end
		else
			inside = true
			end
		v._inside = inside
		v.Inside = v._inside
		end
	if inside then
		--Wherigo.LogMessage("Zone <" .. v.Name .. ">: Inside")
		v.State = 'Inside'
		v._state = v.State
	else
		if v.CurrentDistance() < (v.ProximityRange() + comfortZone) then
			if v._state == 'NotInRange' and v.OnDistant then
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: START onDistant")
				v.OnDistant (v)
				Wherigo.LogMessage("Zone <" .. v.Name .. ">: END__ onDistant")
				update_all = true
				end
			--Wherigo.LogMessage("Zone <" .. v.Name .. ">: Distant")
			v.State = 'Proximity'
		elseif v.DistanceRange() < 0 or v.CurrentDistance() < (v.DistanceRange() + comfortZone) then
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



--- ZCartridge object extend ZObject. Global cartridge object to store all
--   game data.
-- @type Wherigo.ZCartridge
Wherigo.ZCartridge = { }
--- Metatable for ZCartridge object. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZCartridge.metatable = {
	__tostring = function(s)
		return "a ZCartridge instance"
		end
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZCartridge.metatable[k] = v end

--- ZCartridge constructor, extend ZObject. Creates new ZCartridge object
--   and initializes all default values and structures for storing all game data
--
--   @return 	ZCartridge object
function Wherigo.ZCartridge.new(  )
	Wherigo.ZCartridge._store = true
	local self = Wherigo.ZObject.new( ) 
	self._classname = Wherigo.CLASS_ZCARTRIDGE
	self._mediacount = -1
	self.AllZObjects = {}
	table.insert(self.AllZObjects, 0, self)
	self.ObjIndex = 0
	self.AllZCharacters = {}
	self.AllZItems = {}
	self.AllZones = {}
	self.AllZTimers = {}
	self.Company = Env._Company
	self.Activity = Env._Activity
	self.ZVariables = {}
	
	self.EmptyInventoryListText = 'No items'
	self.EmptyTasksListText = 'No new tasks'
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
	
	--- Request cartridge synchronization (store runtime data to file). 
	--   Only accepts the request and waits for the end of lua call stack
	--   and then stores data.
	-- 
	--   @class function
	--   @name Wherigo.ZCartridge:RequestSync
	function self:RequestSync()
		Wherigo.LogMessage("ZCartridge:RequestSync")
		if self.OnSync then
			Wherigo.LogMessage("ZCartridge: START onSync")
			self.OnSync(self)
			Wherigo.LogMessage("ZCartridge: END__ onSync")
			end
		WIGInternal.RequestSync();
		end
	
	--- Request all Z* objects by type
	-- 
	--   @class function
	-- @name Wherigo.ZCartridge:GetAllOfType
	-- @param t Requested type
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
	
	--- Process position update. Internal use only!
	-- 
	--   @class function
	--   @name Wherigo.ZCartridge._update
	--   @param	position	ZonePoint object with player location
	--   @param	t			Time to update timers
	--   @param accuracy	GPS position accuracy
	--   @return 	If something changed, request GUI update
	function self._update(position, t, accuracy)
		for k,v in pairs(self.AllZObjects) do
			if v._classname == Wherigo.CLASS_ZTIMER and v._target ~= nil then
				v.Remaining = v._target - t
				end
			end
		local update_all = false
		if not position then
			return false end
		Wherigo.Player.ObjectLocation = position
		Wherigo.Player.PositionAccuracy = Wherigo.Distance(accuracy)
		Wherigo.Player.LastLocationUpdate = t
		for k,v in pairs(self.AllZObjects) do
			if (v._classname == Wherigo.CLASS_ZITEM or v._classname == Wherigo.CLASS_ZCHARACTER)
					and v.Container ~= Wherigo.Player then
				local pos = v._get_pos()
				if pos then
					v.CurrentDistance, v.CurrentBearing = Wherigo.VectorToPoint(Wherigo.Player.ObjectLocation, pos)
					end
			elseif v._classname == Wherigo.CLASS_ZONE and v.Active then
				update_all = Wherigo.Zone._update(v) or update_all
				end
			end
		return update_all
		end
	
	setmetatable(self, Wherigo.ZCartridge.metatable) 
	return self
	end
--- Check membership of given object to class ZCartridge
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZCartridge:made( object )
	return (object._classname == Wherigo.CLASS_ZCARTRIDGE)
	end
setmetatable(Wherigo.ZCartridge, {
	__call = function(s)
		return Wherigo.ZCartridge.new()
		end
	}) 

--- ZMedia object extend ZObject. Media object with defined resources.
-- @type Wherigo.ZMedia
Wherigo.ZMedia = {}
--- Metatable for ZMedia objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZMedia.metatable = {
	__tostring  = function(s)
		return "a ZMedia instance"
		end
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZMedia.metatable[k] = v end

--- ZMedia constructor, extend ZObject. Creates new ZMedia object
--   and initializes default values. Parameters can be in table.
--
--   @param cartridge ZCartridge object of global cartridge
--   @return 	ZMedia object
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
	self.Visible = false
	self._id = self.Cartridge._mediacount
	if self.Cartridge._mediacount > 0 then
		self.Cartridge._mediacount = self.Cartridge._mediacount + 1;
		end
	setmetatable(self, Wherigo.ZMedia.metatable) 

	return self
	end
--- Check membership of given object to class ZMedia
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZMedia:made( object )
	return (object._classname == Wherigo.CLASS_ZMEDIA)
	end
setmetatable(Wherigo.ZMedia, {
	__call = function(s, cartridge)
		return Wherigo.ZMedia.new(cartridge)
		end
	}) 

--- ZItem object extend ZObject. Item that can be seen or that can be in
--   inventory. This can have also some ZCommands.
-- @type Wherigo.ZItem
Wherigo.ZItem = {}
--- Metatable for ZItem objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZItem.metatable = {
	__tostring = function( s )
		return "a ZItem instance"
		end,
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZItem.metatable[k] = v end

--- ZItem constructor, extend ZObject. Creates new ZItem object
--   and initializes default values. Parameters can be in table.
--
--   @param cartridge ZCartridge object of global cartridge
--   @param container Default container tu put
--   @return 	ZItem object
function Wherigo.ZItem.new( cartridge, container )
	local self = Wherigo.ZObject.new(cartridge, container)
	self._classname = Wherigo.CLASS_ZITEM
	table.insert(self.Cartridge.AllZItems, self)
	self._target = nil
	
	setmetatable(self, Wherigo.ZItem.metatable)
	
	return self
	end
--- Check membership of given object to class ZItem
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZItem:made( object )
	return (object._classname == Wherigo.CLASS_ZITEM)
	end
setmetatable(Wherigo.ZItem, {
	__call = function(s, cartridge, container)
		return Wherigo.ZItem.new( cartridge, container )
		end
	})

--- ZTask object extends ZObject. Tasks given to player. Showing or hiding,
--   but keeps user in track what to do.
-- @type Wherigo.ZTask
Wherigo.ZTask = {
	tasks = 0
}
--- Metatable for ZTask objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZTask.metatable = {
	__tostring = function( s )
		return "a ZTask instance"
		end,
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZTask.metatable[k] = v end

--- ZTask constructor, extend ZObject. Creates new ZTask object
--   and initializes default values. Parameters can be in table.
--   Also keeps track of all tasks to set default SortOrder.
--
--   @param cartridge ZCartridge object of global cartridge
--   @param container Default location of object. Can be moved later by calling Wherigo.ZObject.MoveTo function
--   @return 	ZTask object
function Wherigo.ZTask.new( cartridge, container )
	-- export CompletedTime
	local self = Wherigo.ZObject.new( cartridge, container )
	self._classname = Wherigo.CLASS_ZTASK
	if self._active == nil then
		self._active = true
		end
	--[[self.Name = 'NoName'
	self.Description = ''
	self.Complete = false
	self.Correct = false]]--
	
	Wherigo.ZTask.tasks = Wherigo.ZTask.tasks + 1
	self.SortOrder = Wherigo.ZTask.tasks
	self.CompletedTime = 0
	
	
	setmetatable(self, Wherigo.ZTask.metatable)
	-- events OnClick, SetCorrectState, OnSetComplete, OnSetActive
	return self
	end
--- Check membership of given object to class ZTask
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZTask:made( object )
	return (object._classname == Wherigo.CLASS_ZTASK)
	end
setmetatable(Wherigo.ZTask, {
	__call = function(s, cartridge, container)
		return Wherigo.ZTask.new(cartridge, container)
		end
	}) 

--- ZTimer object extends ZObject. Can invoke action in some time.
-- @type Wherigo.ZTimer
Wherigo.ZTimer = {}
--- Metatable for ZTask objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZTimer.metatable = {
	__tostring = function( s )
		return "a ZTimer instance"
		end,
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZTimer.metatable[k] = v end
--- ZTimer constructor, extend ZObject. Creates new ZTimer object
--   and initializes default values. Parameters can be in table.
--
--   @param cartridge ZCartridge object of global cartridge
--   @return 	ZTimer object
function Wherigo.ZTimer.new(cartridge)
	self = Wherigo.ZObject.new(cartridge)
	self.Type = self.Type or 'Countdown' -- Countdown or Interval
	self.Duration = self.Duration or -1
	self.Remaining = self.Remaining or -1
	self.Running = 0
	self.StartTime = 0
	--[[self.OnStart = nil
	self.OnStop = nil
	self.OnTick = nil]]
	
	self._classname = Wherigo.CLASS_ZTIMER
	self._target = nil -- target time
	
	--- Starts timer (countdown) and execute attached event
	-- 
	--   @class function
	--   @name Wherigo.ZTimer:Start
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
		self._target = WIGInternal.addTimer(self.Remaining, self.ObjIndex)
		self.StartTime = WIGInternal.getTime()
		self.Running = 1
		end
	--- Stops this timer and execute attached event
	-- 
	--   @class function
	--   @name Wherigo.ZTimer:Stop
	function self:Stop()
		if self._target == nil then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Not stopping. Not running")
			return
			end
		Wherigo.LogMessage("ZTimer <" .. self.Name .. " (" .. self.ObjIndex .. ")>: Stop")
		-- native timer
		WIGInternal.removeTimer(self.ObjIndex)
		self.Running = 0
		self._target = nil
		if self.OnStop then
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: START OnStop")
			self.OnStop(self)
			Wherigo.LogMessage("ZTimer <" .. self.Name .. ">: END__ OnStop")
			end
		
		end
	--- Timer expired. Desired action is executed and timer reset.
	--   if type is interval, then it starts again
	-- 
	--   @class function
	--   @name Wherigo.ZTimer:Tick
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

	setmetatable(self, Wherigo.ZTimer.metatable)
	
	return self
	end
--- Check membership of given object to class ZTimer
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZTimer:made( object )
	return (object._classname == Wherigo.CLASS_ZTIMER)
	end
setmetatable(Wherigo.ZTimer, {
	__call = function(s, cartridge)
		return Wherigo.ZTimer.new(cartridge)
		end
	})
--- Internaly used function to call from C API.
--   Calls desired Tick event by given id in AllZObjects table
--
--   @param id	ID from AllZobjects table
function Wherigo.ZTimer._Tick(id)
	local t = cartridge.AllZObjects[id]
	if t._classname == Wherigo.CLASS_ZTIMER then
		t.Tick(t) end
	end

--- ZInput object extends ZObject. Request input from user. Can be text or
--   multiple choice
-- @type Wherigo.ZInput
Wherigo.ZInput = {}
--- Metatable for ZInput objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZInput.metatable = {
	__tostring = function( s )
		return "a ZInput instance"
		end,
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZInput.metatable[k] = v end
--- Zinput constructor, extend ZObject. Creates new Zinput object
--   and initializes default values. Parameters can be in table.
--
--   @param cartridge ZCartridge object of global cartridge
--   @return 	ZTimer object
function Wherigo.ZInput.new( cartridge )
	local self = Wherigo.ZObject.new( cartridge )
	self._classname = Wherigo.CLASS_ZINPUT
	--[[
	OnGetInput event
	]]
	self.Choices = {}
	setmetatable(self, Wherigo.ZInput.metatable)
	
	return self
	end
--- Check membership of given object to class ZInput
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZInput:made( object )
	return (object._classname == Wherigo.CLASS_ZINPUT)
	end
setmetatable(Wherigo.ZInput, {
	__call = function(s, cartridge)
		return Wherigo.ZInput.new(cartridge)
		end
	})


--- ZCharacter object extends ZObject. Player or other character to be seen in 
--   inventory or in nearby zones.
-- @type Wherigo.ZCharacter
Wherigo.ZCharacter = {}
--- Metatable for ZCharacter objects. Implements tostring as required by
--   cartridges. Other metamethods are inherited from ZObject
Wherigo.ZCharacter.metatable = {
	__tostring = function( s )
		return "a ZCharacter instance"
		end,
}
for k,v in pairs(Wherigo.ZObject.metatable) do Wherigo.ZCharacter.metatable[k] = v end
--- ZCharacter constructor, extend ZObject. Creates new ZCharacter object
--   and initializes default values. Parameters can be in table.
--
--   @param cartridge ZCartridge object of global cartridge
--   @param container Default container for character
--   @return 	ZCharacter object
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
	self.Gender = self.Gender or "It"
	
	setmetatable(self, Wherigo.ZCharacter_metatable)
	
	return self
	end
--- Check membership of given object to class ZCharacter
--   @param object Some object to test
--   @return True if object is a member of class
function Wherigo.ZCharacter:made( object )
	return (object._classname == Wherigo.CLASS_ZCHARACTER)
	end
setmetatable(Wherigo.ZCharacter, {
	__call = function(s, cartridge, container)
		return Wherigo.ZCharacter.new(cartridge, container)
		end
	}) 

--WIGInternal = {}

--- Global object representing player as ZCharacter with position.
-- 
--   @type Wherigo.Player
--   @field CompletionCode - Secret code to unlock cartridge on wherigo portal. Set from GWC head
--   @field ObjIndex = 0xabcd - taken from savegame. Since Player is created before ZCartridge, it can't be numbered as other objects
--   @field Name Username of player, it was downloaded for
Wherigo.Player = Wherigo.ZCharacter.new()
Wherigo.Player.Name = Env._Player
Wherigo.Player.Id = -1
Wherigo.Player.CompletionCode = Env._CompletionCode
Wherigo.Player.InsideOfZones = {}
Wherigo.Player.CurrentDistance = nil
Wherigo.Player.CurrentBearing = nil
Wherigo.Player.PositionAccuracy = Wherigo.Distance(5)
Wherigo.Player.ObjIndex = 0xabcd -- ID taken from Emulator to identify references

--- Request new position update for special application. Required by some
--   cartridges. There is not implemented since I can't see point in it.
function Wherigo.Player:RefreshLocation()
	-- request refresh location ... useless?
	end
--- Remove zone from InsideOfZones table of Player. Required for runtime 
--   for some cartridges and used for savegame. Internal use only!
--   @param zone Zone object to remove
function Wherigo.Player._removeFromZone(zone)
	for i,t in pairs(Wherigo.Player.InsideOfZones) do
		if t == zone then
			table.remove(Wherigo.Player.InsideOfZones, i)
			end
		end
	end


-- should be for correctness, but I can't simply detect this value
Wherigo._INVALID_ZONEPOINT = Wherigo.ZonePoint(360,360,360)

