enyo.kind({
	name: "WIGApp.GameMain",
	kind: enyo.VFlexBox,
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Wherigo name"},
			{kind: "Spacer"}
		]},
		{kind: enyo.VFlexBox, flex: 1, components: [
			
			{name: "locations", kind: "WIGApp.GameMain.ActionRow"},
			{name: "youSee", kind: "WIGApp.GameMain.ActionRow"},
			{name: "inventory", kind: "WIGApp.GameMain.ActionRow"},
			{name: "tasks", kind: "WIGApp.GameMain.ActionRow"},
		]},
	],
	create: function(){
		this.inherited(arguments);
		this.$.locations.$.icon.setSrc("images/locations.png");
		this.$.locations.$.title.setContent("Locations");
		this.$.youSee.$.icon.setSrc("images/you_see.png");
		this.$.youSee.$.title.setContent("You see");
		this.$.inventory.$.icon.setSrc("images/inventory.png");
		this.$.inventory.$.title.setContent("Inventory");
		this.$.tasks.$.icon.setSrc("images/tasks.png");
		this.$.tasks.$.title.setContent("Tasks");
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
