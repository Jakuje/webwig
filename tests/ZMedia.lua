cart = Wherigo.ZCartridge()

media = Wherigo.ZMedia(cart)
assert(media._id == 1, "Wrong internal id for first media - expected 1, got " .. media._id)

media = Wherigo.ZMedia.new(cart)
assert(media._id == 2, "Wrong internal id for media - expected 2, got " .. media._id)
