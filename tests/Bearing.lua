-- Wherigo.Bearing

angle = Wherigo.Bearing(10)
assert(angle.value == 10, "Error Wherigo.Bearing(): wrong result")
angle = Wherigo.Bearing.new(10)
assert(angle.value == 10, "Error Wherigo.Bearing.new(): wrong result")

angle = Wherigo.Bearing(370)
assert(angle.value == 10, "Error Wherigo.Bearing(): modulo error")


angle = Wherigo.Bearing(0)
assert(angle.value == 0, "Error Wherigo.Bearing(): wrong result got " .. angle.value .. " expected " .. 0)
angle = Wherigo.Bearing.new(-90)
assert(angle.value == 270, "Error Wherigo.Bearing.new(): wrong modulo got " .. angle.value .. " expected " .. 270)
print(angle)
