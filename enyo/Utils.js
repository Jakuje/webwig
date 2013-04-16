Number.prototype.toRad = function () { return this * Math.PI / 180; }
Number.prototype.toDeg = function () { return this / Math.PI * 180; }

enyo.kind({
	name: "WIGApp.Utils",
	kind: "Component",
	components: [],
	/**
	 * Returns distance between two poins on Earth's sphere in kilometers
	 */
	VectorToPoint: function(p1, p2){
		var lat1 = p1[0];
		var lon1 = p1[1];
		var lat2 = p2[0];
		var lon2 = p2[1];
		
		// http://www.movable-type.co.uk/scripts/latlong.html
		var R = 6371; // km
		var dLat = (lat2-lat1).toRad();
		var dLon = (lon2-lon1).toRad();
		var lat1 = lat1.toRad();
		var lat2 = lat2.toRad();
		
		// distance
		var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
				Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
		var d = R * c;
		
		// bearing
		var y = Math.sin(dLon) * Math.cos(lat2);
		var x = Math.cos(lat1)*Math.sin(lat2) -
				Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon);
		var brng = Math.atan2(y, x).toDeg();
		return [d, brng];
	},
});
