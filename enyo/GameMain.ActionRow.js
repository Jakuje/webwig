enyo.kind({
	name: "WIGApp.GameMain.ActionRow",
	kind: enyo.HFlexBox,
	flex: 1,
	components: [
		{kind: "Item", layoutKind: "VFlexLayout", pack: "center",
		align: "center", style: "width: 100px;", onclick: "showScreen", components: [
			{name: "icon", kind: "Image", src: "images/you_see.png"},
			{name: "title", content: "You See"},
			{name: "numRows", content: "0"}
		]},
		{kind: "Scroller", flex: 1, components: [
			{kind: "VirtualRepeater", name: "items", onSetupRow: "getItem", components: [
				{kind: "Item", layoutKind: "HFlexLayout", onclick: "itemClicked", components: [
					{name: "itemIcon", kind: "Image", style: "width: 25px;height:25px;margin-right:3px;"},
					{name: "itemTitle"},
					{kind: "Spacer"},
					{name: "itemDistance", showing: "false"},
				]}
			]},
			{kind: "Item", name: "empty", layoutKind: "HFlexLayout", components: [
				{content: "Nothing here", flex: 1, style: "font-style:italic;text-align:center; color:#999999;"}
			]}
		]}
	],
	screen: "",
	getTitle: function(name){
		switch(name){
			case 'locations':
				return "Locations";
			case 'youSee':
				return "You see";
			case 'inventory':
				return "Inventory";
			case 'tasks':
				return "Tasks";
		}
	},
	itemClicked: function(inSender, inEvent){
		if( this.data[inEvent.rowIndex].onclick ){
			if( typeof this.data[inEvent.rowIndex].onclick == 'function') {
				// debug UI
				this.data[inEvent.rowIndex].onclick(this.owner);
			} else {
				this.owner.owner.owner.$.plugin.callback("OnClick", this.data[inEvent.rowIndex].id)
			}
		} else {
			this.owner.owner.showScreen(this.screen, inEvent.rowIndex);
		}
	},
	showScreen: function(){
		this.owner.owner.showScreen(this.screen);
	},
	
	data: [],
	setup: function(data, screen){
		if( ! screen ){
			screen = this.name;
		}
		this.screen = screen;
		this.$.title.setContent( this.getTitle(this.screen) );
		this.$.icon.setSrc("images/" + this.screen + ".png");
		
		if( data ){
			this.data = data;
			this.$.numRows.setContent(data.length);
			this.render();
			if( data.length == 0 ){
				this.$.empty.show()
			} else {
				this.$.empty.hide()
			}
		}
	},
	getItem: function(inSender, inIndex){
		if (inIndex < this.data.length) {
			this.$.itemTitle.setContent(this.data[inIndex].name);
			if( this.data[inIndex].icon ){
				this.$.itemIcon.setSrc(this.data[inIndex].icon);
				this.$.itemIcon.show();
			} else {
				this.$.itemIcon.hide();
			}
			if( this.screen == 'locations' ){
				d = this.data[inIndex].distance;
				if( d == 0 ){
					this.$.itemDistance.setContent("here");
				} else {
					this.$.itemDistance.setContent( Math.round(d) + " m");
				}
				this.$.itemDistance.show()
			} else {
				this.$.itemDistance.setContent("");
				this.$.itemDistance.hide();
			}
			return true;
		}
	}
});
