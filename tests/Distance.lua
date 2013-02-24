-- Wherigo.Distance

dist = Wherigo.Distance(10)
assert(dist.value == 10, "wrong result for default units: \"value\" ")
assert(dist() == 10, "wrong result for default units \"call\" ")
assert(dist.getValue() == 10, "wrong result for default units \"getValue()\" ")
assert(dist.getValue("meters") == 10, "wrong result for default units \"getValue(meters)\" ")
assert(dist.getValue("m") == 10, "wrong result for default units \"getValue(m)\" ")

dist = Wherigo.Distance.new(10, "m")
assert(dist.value == 10, "wrong result for meters: \"value\" ")
assert(dist() == 10, "wrong result for meters \"call\" ")
assert(dist.getValue() == 10, "wrong result for meters \"getValue()\" ")
assert(dist.getValue("meters") == 10, "wrong result for meters \"getValue(meters)\" ")
assert(dist.getValue("m") == 10, "wrong result for meters \"getValue(m)\" ")


dist = Wherigo.Distance(100, "feet")
assert(dist.value == 30.48, "wrong result for feets: \"value\" ")
assert(dist.getValue() == 30.48, "wrong result for feets \"getValue()\" ")
assert(dist.getValue("meters") == 30.48, "wrong result for feets \"getValue(meters)\" ")
assert(dist.getValue("feet") == 100, "wrong result for feets \"getValue(feet)\" ")
print(dist)


-- todo Comparing ...
--assert(false, "Missing comparing test")
