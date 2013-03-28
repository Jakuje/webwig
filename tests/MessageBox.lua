
-- simple message
Wherigo.MessageBox({Text = "Message content"})


-- with media
cart = Wherigo.ZCartridge()
media = Wherigo.ZMedia(cart)
media.Id = "ca2faabc5164-ca2faabc5164"

Wherigo.MessageBox({Text = "Message content", Media = media})


-- with buttons
Wherigo.MessageBox({Text = "Message content", Media = media, Buttons = {"ok", "cancel"} })

-- with callback
called = false
functioncall = function ( action )
	print ("MessageBox: Callback called >> Action: " .. action)
	called = true
	end

Wherigo.MessageBox({Text = "Message content", Media = media, Buttons = {"ok", "cancel"}, Callback = functioncall })

--assert(called, "Callback was not invoked")
