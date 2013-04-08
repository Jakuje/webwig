enyo.kind({
	name: "WIGApp.Preferences",
	kind: enyo.VFlexBox,
	events: { 
		onPlay: ""
	},
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Preferences"},
			{kind: "Spacer"}
		]},
		{kind: "RowGroup", caption: "GPS", components: [
			{layoutKind: "HFlexLayout", align: "center", components: [
				{content: "auto-enable GPS", className: "enyo-menucheckitem-caption", flex: 1},
				{name: "gps", pack: "end", kind: "ToggleButton", onChange: "prefsChange"}
			]},
			{kind: "HFlexBox", align: "center", components: [
				{name: "compass", label: "Compass orientation", kind: "ListSelector",
				flex: 1, value: 1, onChange: "prefsChange", items: [
					{caption: "Bearing", value: 1},
					{caption: "North", value: 2},
					{caption: "Magnetic bearing", value: 3}
				]}
			]},
		]},
		{kind: "RowGroup", caption: "Regional setings", components: [
			{kind: "HFlexBox", align: "center", components: [
				{content: "Units", className: "enyo-menucheckitem-caption", flex: 1},
				{name: "units", pack: "end", kind: "ToggleButton", onChange: "prefsChange", onLabel: "Metric", offLabel: "Imperial"}
			]},
		]},
	],
	create: function(){
		this.inherited(arguments);
	},
	setup: function(){
		this.$.gps.setState( this.owner.getPrefs('gps') );
		this.$.compass.setValue( this.owner.getPrefs('compass') );
		this.$.units.setState( this.owner.getPrefs('units') );
	},
	
	prefsChange: function(inSender, inValue, inOldValue){
		if( inValue != inOldValue ){
			console.log(inSender.name, inValue);
			this.owner.setPrefs(inSender.name, inValue);
		}
	},
	
	goBack: function(inSender, inEvent){
		this.owner.goBack(inSender, inEvent);
	}
});