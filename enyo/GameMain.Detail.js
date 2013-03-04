enyo.kind({
	name: "WIGApp.GameMain.Detail",
	kind: enyo.VFlexBox,
	flex: 1,
	components: [
		{className: "enyo-row", components: [
			{kind: "ButtonHeader", components: [
				{name: "title", content: "Header", style: "text-align: center; width: 100%;"}
			]}
		]},
		{kind: "Scroller", flex: 1, components: [
			{kind: "Item", components: [
				{name: "image", kind: "Image"},
				{name: "description", allowHtml: true}
				]
			}]
		}
		],
	setup: function(screen, data){
		this.screen = screen;
		this.data = data;
		this.$.title.setContent( this.owner.$.gList.$.detail.getTitle(screen) + ": " + data.name );
		this.$.description.setContent( data.description );
		if( data.media ) {
			this.$.image.setSrc( data.media );
			this.$.image.show();
		} else {
			this.$.image.hide();
		}
			
	},
	
	updateUI: function(data){
		this.data = data[screen];
		//this.$.detail.setup( data[this.screen] );
	}
});
