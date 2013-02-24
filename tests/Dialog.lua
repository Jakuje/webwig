
-- simple message
Wherigo.Dialog({Text = "Message content"})


-- with media
cart = Wherigo.ZCartridge()
media = Wherigo.ZMedia(cart)
media.Id = "ca2faabc5164-ca2faabc5164"

Wherigo.MessageBox({Text = "Message content", Media = media})
