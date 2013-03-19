cart = Wherigo.ZCartridge()

-- Testing constructor with 

  local dist = Wherigo.Distance(150, 'm')
  local newZp = Wherigo.TranslatePoint(Wherigo.ZonePoint(49, 16, 0), dist, math.random(0, 360))   -- new center point for the new zone	
  dist = Wherigo.Distance(10, 'ft')
  local pts = {
    Wherigo.TranslatePoint(newZp, dist, 45),
    Wherigo.TranslatePoint(newZp, dist, 135),
    Wherigo.TranslatePoint(newZp, dist, 225),
    Wherigo.TranslatePoint(newZp, dist, 315),
  }


local tempz = Wherigo.Zone{
    Cartridge = cart,
    Name = "Name",
    OutOfRangeName = "",
    InRangeName = "",		
    Description = [[]],
    Visible = false,
    --Active = false,
    DistanceRange = Wherigo.Distance(-1, "feet"),
    ShowObjects = "OnEnter",
    ProximityRange = Wherigo.Distance(30, "feet"),
    AllowSetPositionTo = false,
    Points = pts,
  }
  
print(tempz, tempz._classname, tempz.Active, tempz._active)
print(Wherigo.Zone)
  
assert(tempz.Name == "Name", "Name is wrong")
assert(tempz.Active == true, "Failed to set default value for Activity")

tempz.Active = true

assert(tempz.Active == true, "Active update OK")
