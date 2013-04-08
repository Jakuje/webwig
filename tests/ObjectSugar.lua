
object = {
	name = "(noone)"
}


object1 = {
	name = "Pepa"
}

object2 = {
	name = "Karel"
}


function object:fce(param)	
	print(object.name, param.name)
	end


object:fce(object2)
object.fce(object, object2)

object.fce(object2, object1)

fce = object["fce"]

fce(object, object1)
fce(object1, object2)
fce(object2, object1)
fce(object, object1)

-- should be equal
fce(null, object2)
object:fce(object2)
