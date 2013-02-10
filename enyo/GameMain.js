enyo.kind({
	name: "WIGApp.GameMain",
	kind: enyo.VFlexBox,
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Wherigo name"},
			{kind: "Spacer"},
		]},
		{kind: enyo.VFlexBox, flex: 1, components: [
			{kind: enyo.HFlexBox, components: [
				{kind: "Image", src: "images/locations.png"},
				{content: "Locations (0)"},
			]},
			{kind: enyo.HFlexBox, components: [
				{kind: "Image", src: "images/you_see.png"},
				{content: "You See (0)"},
			]},
			{kind: enyo.HFlexBox, components: [
				{kind: "Image", src: "images/Inventory.png"},
				{content: "Inventory (0)"},
			]},
			{kind: enyo.HFlexBox, components: [
				{kind: "Image", src: "images/tasks.png"},
				{content: "Tasks (0)"},
			]},
		]},
		{ kind: enyo.ApplicationEvents, onBack: "goBack" }
	],
	create: function(){
		this.inherited(arguments);
	},
	
	setup: function(data){
		this.$.title.setContent(data.name);
		/*if(data.iconID != "-1"){
			this.$.icon.setIcon(CONF_DIR + data.guid + '_icon.png');
		} else {
			this.$.icon.setIcon('');
		}
		if(data.splashID != "-1"){
			this.$.splash.setSrc(CONF_DIR + data.guid + '_splash.png');
		} else {
			this.$.splash.setSrc('');
		}
		this.$.description.setContent(data.description);
		this.$.startDescription.setContent(data.startingLocationDescription);
		this.$.type.setContent(data.type);
		this.$.version.setContent(data.version);
		this.$.author.setContent(data.author);
		*/
	},
	
	goBack: function(inSender, inEvent){
		this.owner.goBack(inSender, inEvent);
	}
});
