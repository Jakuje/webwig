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
		{name: "description"},
		],
	setup: function(screen, data){
		
	},
	
	updateUI: function(data){
		//this.$.detail.setup( data[this.screen] );
	}
});
