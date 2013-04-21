enyo.kind({
	name: "WIGApp.Waypoint",
	kind: enyo.VFlexBox,
	flex: 1,
	components: [
	{kind: "Scroller", flex: 1, components: [
		{kind: "RowGroup", caption: "Source point", components: [
			{kind: "Input", name: "lat", value: "", onchange: "count", autoKeyModifier: "num-lock", components: [
				{ content: "Latitude", className: "enyo-label"}
				]},
			{kind: "Input", name: "lon", value: "", onchange: "count", autoKeyModifier: "num-lock", components: [
				{ content: "Longitude", className: "enyo-label"}
				]},
			{kind: "HFlexBox", components: [
				{
					kind: "ActivityButton",
					flex: 1,
					name: "locate",
					caption: "Get current location",
					onclick: "getCurrent"},
				]},
			]
		},
		{kind: "RowGroup", caption: "Offset", components: [
			{kind: "Input", name: "dist", value: "", onchange: "count", autoKeyModifier: "num-lock", components: [
				{ content: "Distance [km]", className: "enyo-label"}
				]},
			{kind: "Input", name: "brng", value: "", onchange: "count", autoKeyModifier: "num-lock", components: [
				{ content: "Bearing", className: "enyo-label"}
				]},
			/*{kind: "HFlexBox", components: [
				{kind: "Button", flex: 1, caption: "Offset", onclick: "count"},
				]},*/
			]
		},
		{kind: "RowGroup", caption: "Destination point", components: [
			{kind: "Input", name: "lat_dest", value: "", components: [
				{ content: "Latitude", className: "enyo-label"}
				]},
			{kind: "Input", name: "lon_dest", value: "", components: [
				{ content: "Longitude", className: "enyo-label"}
				]},
			{kind: "HFlexBox", components: [
				{kind: "Button", flex: 1, caption: "Show in map", className: "enyo-button-affirmative", onclick: "showMap"},
				]},
			]
		},
		{
			name      : "getLocation",
			kind      : "PalmService",
			service   : "palm://com.palm.location/",
			method    : "getCurrentPosition",
			onSuccess : "gotPosition",
			onFailure : "gotPositionError",
		},
		]
	}],
	create: function(){
		this.inherited(arguments);
	},
	count: function(){
		var p2 = this.owner.$.utils.TranslatePoint(
			[Number(this.$.lat.getValue()), Number(this.$.lon.getValue())],
			Number(this.$.dist.getValue()), Number(this.$.brng.getValue())
		);
		this.$.lat_dest.setValue(p2[0]);
		this.$.lon_dest.setValue(p2[1]);
	},
	showMap: function(){
		this.owner.$.mappingTool.call({
			'id': 'de.metaviewsoft.maptool',
			'params': [{
				"name": "Point",
				"lat": this.$.lat_dest.getValue(),
				"lon": this.$.lon_dest.getValue()
			}],
		});
	},
	getCurrent: function(){
		this.$.locate.setActive(true);
		this.$.locate.setDisabled(true);
		this.$.getLocation.call({});
	},
	gotPosition: function(inSender, inResponse){
		this.$.locate.setActive(false);
		this.$.locate.setDisabled(false);
		this.$.lat.setValue(inResponse.latitude);
		this.$.lon.setValue(inResponse.longitude);
		this.count();
	},
	gotPositionError: function(inSender, inResponse){
		this.$.locate.setActive(false);
		this.$.locate.setDisabled(false);
	},
});
