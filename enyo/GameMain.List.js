enyo.kind({
	name: "WIGApp.GameMain.List",
	kind: enyo.VFlexBox,
	flex: 1,
	components: [
		{name: "detail", kind: "WIGApp.GameMain.ActionRow"},
		],
	screen: "you_see",
	setup: function(screen, data){
		this.screen = screen;
		this.$.detail.setup( data[screen], this.screen );
		this.owner.setSubtitle(this.$.detail.getTitle(screen) );
	},
	
	updateUI: function(data){
		this.$.detail.setup( data[this.screen], this.screen );
	}
});
