
-- made methods
cart = Wherigo.ZCartridge()

ZonePoint = Wherigo.ZonePoint
-- ZCartridge
assert(Wherigo.ZCartridge:made(cart), "ZCartridge is made")
assert(Wherigo.Zone:made(cart) == false, "ZCartridge is not made")

zone = Wherigo.Zone(cart)
zone.Name = "Paloucek"
zone.Points = {
	ZonePoint(49.22741, 16.62242, 0),
	ZonePoint(49.22741, 16.62261, 0),
	ZonePoint(49.22729, 16.62261, 0),
}
zone.OriginalPoint = ZonePoint(49.22735, 16.622517, 0)
-- ZonePoint
assert(Wherigo.ZonePoint:made(zone.OriginalPoint), "ZonePoint is made")
assert(Wherigo.ZCartridge:made(zone.OriginalPoint) == false, "ZonePoint is not made")

-- Zone
assert(Wherigo.Zone:made(zone), "Zone is made")
assert(Wherigo.ZonePoint:made(zone) == false, "Zone is not made")

zmediaFeuerglocke = Wherigo.ZMedia(cart)
zmediaFeuerglocke.Name="Feuerglocke"
zmediaFeuerglocke.Resources = { -- WTF???
{ Type = "mp3", Filename = "Glocke.mp3", Directives = {},},
{ Type = "fdl", Filename = "Glocke.fdl", Directives = {},},
} 
-- ZMedia
assert(Wherigo.ZMedia:made(zmediaFeuerglocke), "ZMedia is made")
assert(Wherigo.ZCommand:made(zmediaFeuerglocke) == false, "ZMedia is not made")

zitemGeldsack = Wherigo.ZItem(cart)
zitemGeldsack.Name="Geldsack"
zitemGeldsack.ObjectLocation = Wherigo.INVALID_ZONEPOINT
zitemGeldsack.Commands = {
  Abstellen = Wherigo.ZCommand{Text="Abstellen", CmdWith=false, Enabled=true, EmptyTargetListText="Hier ist nichts, wo man den Geldsack abstellen koennte."},
}
zitemGeldsack.Commands.Abstellen.Custom = true
zitemGeldsack.Commands.Abstellen.WorksWithAll = true

-- ZItem
assert(Wherigo.ZItem:made(zitemGeldsack), "ZItem is made")
assert(Wherigo.ZCharacter:made(zitemGeldsack) == false, "ZItem is not made")

-- ZCommand
assert(Wherigo.ZCommand:made(zitemGeldsack.Commands.Abstellen), "ZCommand is made")
assert(Wherigo.ZItem:made(zitemGeldsack.Commands.Abstellen) == false, "ZCommand is not made")

-- another acces to ZCommand
assert(Wherigo.ZCommand:made(zitemGeldsack.Commands["Abstellen"]), "ZCommand is made")
assert(Wherigo.ZItem:made(zitemGeldsack.Commands["Abstellen"]) == false, "ZCommand is not made")

ztaskFeuerspritzenreparieren = Wherigo.ZTask(cart)
ztaskFeuerspritzenreparieren.Name="Feuerspritzen reparieren"

-- ZTask
assert(Wherigo.ZTask:made(ztaskFeuerspritzenreparieren), "ZTask is made")
assert(Wherigo.ZCartridge:made(ztaskFeuerspritzenreparieren) == false, "ZTask is not made")

ztimerMarktplatzfeuer1 = Wherigo.ZTimer(cart)
ztimerMarktplatzfeuer1.Name="Marktplatzfeuer1"
ztimerMarktplatzfeuer1.Duration=360
ztimerMarktplatzfeuer1.Type="Countdown"

-- ZTimer
assert(Wherigo.ZTimer:made(ztimerMarktplatzfeuer1), "ZTimer is made")
assert(Wherigo.ZTask:made(ztimerMarktplatzfeuer1) == false, "ZTimer is not made")

zinputGutscheincode = Wherigo.ZInput(cart)
zinputGutscheincode.Name="Gutscheincode"

-- ZInput
assert(Wherigo.ZInput:made(zinputGutscheincode), "ZInput is made")
assert(Wherigo.ZTask:made(zinputGutscheincode) == false, "ZInput is not made")
