enyo.kind({
	name: "WIGApp.GameMain.List",
	kind: enyo.VFlexBox,
	flex: 1,
	components: [
		{className: "enyo-row", components: [
			{kind: "ButtonHeader", layoutKind: "HFlexLayout", components: [
				{name: "icon", kind: "Image", src: "images/locations.png", style: "margin: -10px 0;"},
				{name: "title", content: "Header", style: "width: 100%;"}
			]}
		]},
		{name: "detail", kind: "WIGApp.GameMain.ActionRow"},
		],
	screen: "you_see",
	setup: function(screen, data){
		this.screen = screen;
		this.$.title.setContent( this.$.detail.getTitle(screen) );
		this.$.detail.setup( data[screen], this.screen );
		this.$.icon.setSrc("images/" + screen + ".png");
	},
	
	updateUI: function(data){
		this.$.detail.setup( data[this.screen], this.screen );
	}
});
