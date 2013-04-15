cart = Wherigo.ZCartridge()
assert(cart.ObjIndex == 0, "ZCartridge() has other index than 0")

cart = Wherigo.ZCartridge.new()
assert(cart.ObjIndex == 0, "ZCartridge.new() has other index than 0")


zone = Wherigo.Zone.new(cart)
assert( zone.Cartridge == cart, "Wrongly set cartridge to ZObject child")
-- ObjIndex of first object is 1
assert( zone.ObjIndex == 1, "ZObject child has got wrong index" )

