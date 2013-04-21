Number.prototype.toRad = function () { return this * Math.PI / 180; }
Number.prototype.toDeg = function () { return this / Math.PI * 180; }

enyo.kind({
	name: "WIGApp.Utils",
	kind: "Component",
	components: [],
	
	/** Earth's radius */
	R: 6371, // km
	/**
	 * Returns distance between two poins on Earth's sphere in kilometers
	 */
	VectorToPoint: function(p1, p2){
		var lat1 = p1[0];
		var lon1 = p1[1];
		var lat2 = p2[0];
		var lon2 = p2[1];
		
		// http://www.movable-type.co.uk/scripts/latlong.html
		var dLat = (lat2-lat1).toRad();
		var dLon = (lon2-lon1).toRad();
		var lat1 = lat1.toRad();
		var lat2 = lat2.toRad();
		
		// distance
		var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
				Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
		var d = this.R * c;
		
		// bearing
		var y = Math.sin(dLon) * Math.cos(lat2);
		var x = Math.cos(lat1)*Math.sin(lat2) -
				Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon);
		var brng = Math.atan2(y, x).toDeg();
		return [d, brng];
	},
	MetersFormat: function(d){
		return ( d < 1500 ? (d.toFixed(1) + " m") : ((d/1000).toFixed(1) + " km") );
	},
	MilesFormat: function(d){
		d = d / 1609.344;
		return ( d < 1500 ? ((d*5280).toFixed(1) + " ft") : (d.toFixed(1) + " miles") );
	},
	FormatDistance: function(d){
		if( this.owner.getPrefs('units') ){ // true == "m"
			return this.MetersFormat( d );
		} else {
			return this.MilesFormat( d );
		}
		
	},
	
	TranslatePoint: function(point, distance, bearing){
		var d = distance/this.R;
		var b = bearing.toRad();
		var lat1 = point[0].toRad();
		var lat2 = Math.asin (Math.sin (lat1) * Math.cos (d) + Math.cos (lat1) * Math.sin (d) * Math.cos(b));
		var lon2 = point[1].toRad() + Math.atan2 (Math.sin(b) * Math.sin (d) * Math.cos (lat1), Math.cos (d) - Math.sin (lat1) * Math.sin (lat2));
		return [lat2.toDeg(),  lon2.toDeg()];
	}
});
