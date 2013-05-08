enyo.kind({
	name: "WIGApp.Main",
	kind: enyo.VFlexBox,
	flex: 1,
	events: { 
		onList: "",
	},
	components: [
	{kind: "Scroller", flex: 1, components: [
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
				{name: "saved", label: "Saved", kind: "ListSelector",
				flex: 1, value: "All", onChange: "prefsChange", items: [
					{caption: "All"},
					{caption: "Yes"},
					{caption: "No"},
				]}
			]},
			{kind: "HFlexBox", align: "center", components: [
				{name: "complete", label: "Completed", kind: "ListSelector",
				flex: 1, value: "All", onChange: "prefsChange", items: [
					{caption: "All"},
					{caption: "Yes"},
					{caption: "No"},
				]}
			]},
			{kind: "Button", caption: "Show Nearby", className: "enyo-button-affirmative", onclick: "showLibrary"},
			{kind: "Button", caption: "Play Anywhere", onclick: "showLibraryAnywhere"},
			]
		},
		{kind: "RowGroup", caption: "Search online", components: [
			{kind: "Input", name: "lat", value: "49.1", onchange: "inputChange", disabled: true, components: [
				{ content: "Latitude", className: "enyo-label"}
				]},
			{kind: "Input", name: "lon", value: "16.5", onchange: "inputChange", disabled: true, components: [
				{ content: "Longitude", className: "enyo-label"}
				]},
			{kind: "HFlexBox", components: [
				{kind: "Button", flex: 1, caption: "Search", disabled: true, onclick: "notImplemented"},
				{kind: "Button", flex: 1, className: "enyo-button-affirmative", caption: "Nearest", disabled: true, onclick: "notImplemented"}
				]},
			]
		},
		{kind: "RowGroup", caption: "Tools", components: [
			{kind: "Button", caption: "Waypoint calculator", className: "enyo-button-affirmative", onclick: "showWaypoint"},
			]
		},
		{kind: "RowGroup", caption: "Preferences", components: [
			{kind: "Button", caption: "Preferences", onclick: "showPreferences"},
			]
		},
		]
	}],
	create: function(){
		this.inherited(arguments);
		this.$.lat.setValue(this.owner.getPrefs('lat'));
		this.$.lon.setValue(this.owner.getPrefs('lon'));
		this.$.type.setValue(this.owner.getPrefs('type'));
		this.$.saved.setValue(this.owner.getPrefs('saved'));
		this.$.complete.setValue(this.owner.getPrefs('complete'));
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
		this.doList(this.$.type.getValue(), this.$.saved.getValue(), this.$.complete.getValue(), false);
	},
	
	showLibraryAnywhere: function(){
		this.doList(this.$.type.getValue(), this.$.saved.getValue(), this.$.complete.getValue(), true);
	},
	
	notImplemented: function(){
		this.owner.popupMessage( new WIGApp.Dialog("Website connector not implemented yet", "Message"));
	},
	
	showWaypoint: function(){
		this.owner.showTools('tWaypoint');
	},
	showPreferences: function(){
		this.owner.showPreferences();
	},
	
});
