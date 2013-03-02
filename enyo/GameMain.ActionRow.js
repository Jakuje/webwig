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
				{kind: "Item", layoutKind: "HFlexLayout", onclick: "showScreenDetail", components: [
					{name: "itemTitle", flex: 1},
				]}
			]},
			{kind: "Item", name: "empty", layoutKind: "HFlexLayout", components: [
				{content: "Nothing here", flex: 1, style: "font-style:italic;text-align:center;"}
			]}
		]}
	],
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
	showScreenDetail: function(inSender, inEvent){
		this.owner.owner.showScreen("detail", inEvent.rowIndex); // todo
	},
	showScreen: function(){
		if( this.name != "detail" ){
			this.owner.owner.showScreen(this.name);
		}
	},
	
	setup: function(data){
		this.$.title.setContent( this.getTitle(this.name) );
		this.$.icon.setSrc("images/" + this.name + ".png");
		
		this.data = data;
		this.$.numRows.setContent(data.length);
		this.render();
		if( data.length == 0 ){
			this.$.empty.show()
		} else {
			this.$.empty.hide()
		}
	},
	data: [],
	getItem: function(inSender, inIndex){
		if (inIndex < this.data.length) {
			this.$.itemTitle.setContent(this.data[inIndex].name);
			return true;
		}
	}
});
