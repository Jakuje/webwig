enyo.kind({
	name: "WIGApp.GameMain.HomeScreen",
	kind: enyo.VFlexBox,
	flex: 1, 
	components: [
		{name: "locations", kind: "WIGApp.GameMain.ActionRow"},
		{name: "youSee", kind: "WIGApp.GameMain.ActionRow"},
		{name: "inventory", kind: "WIGApp.GameMain.ActionRow"},
		{name: "tasks", kind: "WIGApp.GameMain.ActionRow"},
	],
	create: function(){
		this.inherited(arguments);
	},
	
	setup: function(){
	},
	
	updateUI: function(data){
		this.$.locations.setup(data.locations, "locations");
		this.$.youSee.setup(data.youSee, "youSee");
		this.$.inventory.setup(data.inventory, "inventory");
		this.$.tasks.setup(data.tasks, "tasks");
	},
});
