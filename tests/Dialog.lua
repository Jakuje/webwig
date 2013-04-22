
-- simple message
Wherigo.Dialog({Text = "Simple message content"})

-- multiple messages
Wherigo.Dialog({
	{Text = "First of multiple"},
	{Text = "Second text"},
	{Text = "Last text"}
})


-- with media
cart = Wherigo.ZCartridge()
media = Wherigo.ZMedia(cart)
media.Id = "ca2faabc5164-ca2faabc5164"

Wherigo.MessageBox({Text = "MessageBox content", Media = media})
