enyo.kind({
	name: "WIGApp.GameMain.ActionRow",
	kind: enyo.HFlexBox,
	flex: 1,
	components: [
		{kind: "Item", layoutKind: "VFlexLayout", pack: "center", name: "leftMarker",
		align: "center", style: "width: 100px;", onclick: "showScreen", components: [
			{name: "icon", kind: "Image", src: "images/you_see.png"},
			{name: "title", content: "You See"},
			{name: "numRows", content: "0"}
		]},
		{kind: "Scroller", flex: 1, horizontal: false, autoHorizontal: false, components: [
			{kind: "VirtualRepeater", name: "items", onSetupRow: "getItem", components: [
				{kind: "Item", layoutKind: "HFlexLayout", onclick: "itemClicked", tapHighlight: true, components: [
					{name: "itemIcon", kind: "Image", style: "width: 32px;height:32px;margin: -10px 3px -10px -5px;"},
					{name: "itemTitle", flex: 1},
					{name: "itemDistance", showing: "false"},
					{name: "itemBearing", kind: "Image", src: "images/arrow.png", showing: "false",
						style: "width: 25px;height:25px;margin: -10px -10px -10px 3px;"},
				]}
			]},
			{kind: "Item", name: "empty", layoutKind: "HFlexLayout", components: [
				{name: "nothingText", content: "Nothing here", flex: 1, style: "font-style:italic;text-align:center; color:#999999;"}
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
			this.owner.owner.showScreen(this.screen,
				( this.data[inEvent.rowIndex].id
					? this.data[inEvent.rowIndex].id
					: 0)
				);
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
		if( this.name == "detail" ){
			this.$.leftMarker.hide();
		}
		this.screen = screen;
		this.$.title.setContent( this.getTitle(this.screen) );
		this.$.icon.setSrc("images/" + this.screen + ".png");
		
		if( data ){
			if( this.name == "tasks" ){
				this.data = [];
				for(var i in data){
					if( !data[i].complete ){
						data[i].key = i;
						this.data.push(data[i]);
					}
				}
			} else if( this.name == "inventory") {
				this.data = data;
			} else { // locations and youSee => Sort by distance
				this.data = data.sort(function(a, b){return a.distance - b.distance;});
			}
			this.$.numRows.setContent(data.length);
			this.render();
			if( this.data.length == 0 ){
				var title = this.owner.owner.details[this.screen + "Empty"];
				this.$.nothingText.setContent( title ? title : "Nothing here");
				this.$.empty.show();
			} else {
				this.$.empty.hide();
			}
		}
	},
	getItem: function(inSender, inIndex){
		if (inIndex < this.data.length) {
			this.$.itemTitle.setContent(this.data[inIndex].name);
			if( this.data[inIndex].icon ){
				this.$.itemIcon.setSrc(this.owner.owner.details.cartDir + this.data[inIndex].icon);
				this.$.itemIcon.show();
			} else if( this.screen == "tasks" ) {
				if( this.data[inIndex].complete ){
					this.$.itemIcon.setSrc('images/task_complete.png');
				} else {
					this.$.itemIcon.setSrc('images/task.png');
				}
				this.$.itemIcon.show();
			} else {
				this.$.itemIcon.hide();
			}
			if( this.screen == 'locations' || (this.screen == 'youSee' && this.data[inIndex].distance) ){
				d = this.data[inIndex].distance;
				if( d == 0 ){
					this.$.itemDistance.setContent("here");
				} else {
					this.$.itemDistance.setContent( ( d < 2000 ? (Math.round(d) + " m") : (Math.round(d/1000) + " km") ) );
				}
				this.$.itemDistance.show();
				var rotate = this.data[inIndex].bearing
				if( this.owner.owner.owner.getPrefs("compass") == 1 ){
					rotate -= this.owner.owner.data.gps.heading;
				}
				this.$.itemBearing.applyStyle("-webkit-transform", "rotate(" + rotate + "deg)");
				this.$.itemBearing.show();
			} else {
				this.$.itemDistance.setContent("");
				this.$.itemDistance.hide();
				this.$.itemBearing.hide();
			}
			return true;
		}
	}
});
