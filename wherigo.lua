package.loaded['Wherigo'] = 1
Wherigo = {}
function Wherigo.MessageBox(table)
	text = rawget(table, "Text")
	media = rawget(table, "Media")
	buttons = rawget(table, "Buttons")
	Callback = rawget(table, "Callback")
	print("Message: ", text) 
	print("Media: ", media.Name)
	if buttons then
		button1 = rawget(buttons, 1)
		button2 = rawget(buttons, 2)
		print("Buttons: ", button1, " _ ", button2)
		end
	end
Wherigo.INVALID_ZONEPOINT = 0 
Wherigo.Distance = 0
 

Wherigo.ZObject = {} 
function Wherigo.ZObject.new(cartridge, container )
	local self = {}
	self.Cartridge = cartridge
	self.Name = "Unnamed"
	self.Media = {}
	if not cartridge then
		--[[ assert ]]
		self.ObjIndex = -1
		return self
		end
	if cartridge._store then
		self.ObjIndex = # cartridge.AllZObjects + 1;
		table.insert(cartridge.AllZObjects, self)
		end
	return self
	end

Wherigo.ZonePoint = {} 
function Wherigo.ZonePoint.new(slf, lat, lon, alt)
	local self = Wherigo.ZonePoint
	self.latitude = lat
	self.longitude = lon
	self.altitude = alt
	return self
	end
setmetatable(Wherigo.ZonePoint, {
	__tostring = function( t )
		return "Zonepoint (" .. t.latitude .. ", " .. t.longitude .. ")"
		end,
	__call = Wherigo.ZonePoint.new,
	}) 


Wherigo.ZCartridge = { }
function Wherigo.ZCartridge.new( slf )
	local self = Wherigo.ZObject.new( ) 
	self.AllZObjects = {}
	self.Name = 'Old name'
	self._mediacount = -1
	self._store = true
	self._mediacount = 1
	self.Media = Wherigo.ZMedia(self)
	self.Media.Id = nil
	Wherigo.Player.Cartridge = self
	
	return self
	end

function Wherigo.ZCartridge._setup_media( self )
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
	
	
setmetatable(Wherigo.ZCartridge, {
	__call = Wherigo.ZCartridge.new
	}) 

Wherigo.ZMedia = {}
function Wherigo.ZMedia.new( slf, cartridge )
	return Wherigo.ZMedia.__init( Wherigo.ZObject.new( cartridge ), cartridge )
	end
function Wherigo.ZMedia.__init( self, cartridge )
	self._id = cartridge._mediacount
	if cartridge._mediacount > 0 then
		cartridge._mediacount = cartridge._mediacount + 1;
		end
	return self
	end
setmetatable(Wherigo.ZMedia, {
	__call = Wherigo.ZMedia.new
	}) 


Wherigo.INVALID_ZONEPOINT = 0;

Wherigo.ZCharacter = {}
function Wherigo.ZCharacter.new( cartridge )
	return Wherigo.ZCharacter.__init( Wherigo.ZObject.new(cartridge),  cartridge)
	end
function Wherigo.ZCharacter.__init( self, cartridge )
	return self
	end


-------------------
----  setup
-------------------

Wherigo.Player = Wherigo.ZCharacter.new( )
Wherigo.Player.Name = "Jakuje"
Wherigo.Player.CompletationCode = "00000"
-- some starting_marker
