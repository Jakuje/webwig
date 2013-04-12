enyo.kind({
	name: "WIGApp.Main",
	kind: enyo.VFlexBox,
	flex: 1,
	events: { 
		onList: "",
	},
	components: [
	{kind: "Scroller", flex: 1, components: [
		{kind: "RowGroup", caption: "Search online", components: [
			{kind: "Input", name: "lat", value: "49", onchange: "inputChange", components: [
				{ content: "Latitude", className: "enyo-label"}
				]},
			{kind: "Input", name: "lon", value: "16", onchange: "inputChange", components: [
				{ content: "Longitude", className: "enyo-label"}
				]},
			{kind: "HFlexBox", components: [
				{kind: "Button", flex: 1, caption: "Search", onclick: "notImplemented"},
				{kind: "Button", flex: 1, className: "enyo-button-affirmative", caption: "Nearest", onclick: "notImplemented"}
				]},
			]
		},
		{kind: "RowGroup", caption: "Library", components: [
			{kind: "HFlexBox", align: "center", components: [
				{name: "type", label: "Cartridge type", kind: "ListSelector",
				flex: 1, value: "All", onChange: "prefsChange", items: [
					{caption: "All"},
					{caption: "Geocache"},
					{caption: "Puzzle"},
					{caption: "TourGuide"},
					{caption: "Fiction"}
				]}
			]},
			{kind: "HFlexBox", align: "center", components: [
				{name: "state", label: "State", kind: "ListSelector",
				flex: 1, value: "All", onChange: "prefsChange", items: [
					{caption: "All"},
					{caption: "New"},
					{caption: "Saved"},
					{caption: "Complete"},
				]}
			]},
			{kind: "Button", caption: "Show Nearby", className: "enyo-button-affirmative", onclick: "showLibrary"},
			{kind: "Button", caption: "Play Anywhere", onclick: "showLibraryAnywhere"},
			]
		},
		]
	}],
	create: function(){
		this.inherited(arguments);
		this.$.lat.setValue(this.owner.getPrefs('lat'));
		this.$.lon.setValue(this.owner.getPrefs('lon'));
		this.$.type.setValue(this.owner.getPrefs('type'));
		this.$.state.setValue(this.owner.getPrefs('state'));
	},
	
	inputChange: function(inSender, inEvent, inValue){
		this.owner.setPrefs(inSender.name, inValue);
	},
	prefsChange: function(inSender, inValue, inOldValue){
		if( inValue != inOldValue ){
			console.log(inSender.name, inValue);
			this.owner.setPrefs(inSender.name, inValue);
		}
	},
	
	showLibrary: function(){
		this.doList(this.$.type.getValue(), this.$.state.getValue(), false);
	},
	
	showLibraryAnywhere: function(){
		this.doList(this.$.type.getValue(), this.$.state.getValue(), true);
	},
	
	notImplemented: function(){
		this.owner.popupMessage( new WIGApp.Dialog("Website connector not implemented yet", "Message"));
	},
});
