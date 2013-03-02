enyo.kind({
	name: "WIGApp.GameMain.List",
	kind: enyo.VFlexBox,
	flex: 1,
	components: [
		{className: "enyo-row", components: [
			{kind: "ButtonHeader", components: [
				{name: "title", content: "Header", style: "text-align: center; width: 100%;"}
			]}
		]},
		{name: "detail", kind: "WIGApp.GameMain.ActionRow"},
		],
	screen: "you_see",
	setup: function(screen, data){
		this.screen = screen;
		this.$.title.setContent( this.$.detail.getTitle(screen) );
		this.$.detail.setup( data[screen] );
	},
	
	updateUI: function(data){
		this.$.detail.setup( data[this.screen] );
	}
});
