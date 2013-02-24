cart = Wherigo.ZCartridge()
assert(cart.ObjIndex == -1, "ZCartridge() has other index then -1")

cart = Wherigo.ZCartridge.new()
assert(cart.ObjIndex == -1, "ZCartridge.new() has other index then -1")


zone = Wherigo.Zone.new(cart)
assert( zone.Cartridge == cart, "Wrongly set cartridge to ZObject child")
-- ObjIndex of first object is 3 (there are 2 media objects created during inicialization of Cartridge)
assert( zone.ObjIndex == 3, "ZObject child has got wrong index" )

