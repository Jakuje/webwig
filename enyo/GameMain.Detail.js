enyo.kind({
	name: "WIGApp.GameMain.Detail",
	kind: enyo.VFlexBox,
	flex: 1,
	components: [
		{kind: "Scroller", flex: 1, components: [
			{kind: "Item", components: [
				{ layoutKind: "VFlexLayout", align: "center", components: [
					{name: "image", kind: "Image"},
				]},
				{name: "description", allowHtml: true}
				]
			},
			{kind: "VirtualRepeater", name: "commands", onSetupRow: "getCommand", components: [
				{kind: "Item", layoutKind: "HFlexLayout", components: [
					{name: "action", kind: "Button", onclick: "executeCommand", flex: 1},
					]}
				]},
			]
		},
		{kind: "HFlexBox", name: "distanceBox", showing: false, components: [
			{ kind: "VFlexBox", flex: 1, showing: DEBUG, components: [
				{ kind: "Input", onkeypress: "onKeypress", autoCapitalize: "lowercase", flex: 1}
			]},
			{ name: "bearingBackground", style: "background: transparent url('images/compass_bg.png') center center no-repeat;", onclick: "toggleCompass", components: [
				{name: "bearingArrow", kind: "Image", src: "images/compass_arrow.png"},
			]},
			{ kind: "VFlexBox", flex: 1, components: [
				{name: "distance", style: "margin-left: -25px;"},
				{kind: "Spacer"},
				{kind: "HFlexBox", components: [
					{kind: "IconButton", icon: "images/map_button.png", onclick: "showMappingTool"},
				]},
				{kind: "Spacer"},
				{kind: "Button", onclick: "moveTo", content: "Move To", showing: DEBUG, style: "margin-left: -15px;"},
			]},
		]},
		],
	screen: null,
	item: null,
	data: [],
	setup: function(screen, data, item){
		this.item = item;
		this.screen = screen;
		this.paint(data);
	},
	paint: function(data){
		var is = false;
		for( var it in data ){
			if( data[it].id == this.item ){
				data = data[it];
				is = true;
				break;
			}
		}
		if( !is ){
			this.owner.goBack();
		}

		var render = false;
		if( data.id != this.data.id || data.media != this.data.media || data.name != this.data.name || data.commands.length != this.data.commands.length ){
			 render = true;
		} else {
			for(var i in this.data.commands ){
				if( typeof data.commands[i] == 'undefined' || this.data.commands[i].id != data.commands[i].id
					|| this.data.commands[i].text != data.commands[i].text ){
						render = true;
				}
			}
		}
		this.data = data;
		this.$.description.setContent( data.description );
		if( data.media ) {
			this.$.image.setSrc( this.owner.details.cartDir + data.media );
			this.$.image.show();
		} else {
			this.$.image.hide();
		}
		if( this.screen == "locations" || (this.screen == "youSee" && data.distance) ){
			this.$.distance.setContent( this.owner.owner.$.utils.FormatDistance(data.distance) );
			if( this.owner.owner.getPrefs("compass") == 1 ){
				this.$.bearingBackground.applyStyle("-webkit-transform", "rotate(" + -this.owner.data.gps.heading + "deg)");
			} else if( this.owner.owner.getPrefs("compass") == 2 ){
				this.$.bearingBackground.applyStyle("-webkit-transform", "rotate(0deg)");
			}
			this.$.bearingArrow.applyStyle("-webkit-transform", "rotate(" + data.bearing + "deg)");
		}
		if( render ){
			if( this.screen == "locations" || (this.screen == "youSee" && data.distance) ){
				this.$.distanceBox.show();
			} else {
				this.$.distanceBox.hide();
			}
			this.render();
		}
		this.owner.$.subtitle.setContent(data.name);
	},
	
	updateUI: function(data){
		this.paint( data );
	},
	
	getCommand: function(inSender, inIndex){
		if (this.data.commands && inIndex < this.data.commands.length) {
			this.$.action.setContent(this.data.commands[inIndex].text);
			return true;
		}
	},
	executeCommand: function(inSender, inEvent){
		event = this.data.commands[inEvent.rowIndex].id;
		this.owner.owner.$.plugin.callback(event, this.data.id)
	},
	moveTo: function(){
		if( this.screen == "locations" || this.screen == "youSee"){
			this.owner.owner.$.plugin.setPosition(this.data.lat, this.data.lon);
		}
	},
	showMappingTool: function(){
		this.owner.owner.$.plugin.showMap(this.data.id);
		/*this.$.mappingTool.call({
			'id': 'de.metaviewsoft.maptool',
			'params': enyo.json.stringify( [{
				'lat': this.data.lat,
				'lon': this.data.lon,
				'name': this.data.name,
				}] )
		});*/
	},
	toggleCompass: function(){
		if( this.$.bearingArrow.getSrc() == "images/compass_arrow.png" ){
			this.$.bearingBackground.applyStyle("background-image", "url('images/compass_bg_large.png')");
			this.$.bearingArrow.setSrc("images/compass_arrow_large.png");
		} else {
			this.$.bearingBackground.applyStyle("background-image", "url('images/compass_bg.png')");
			this.$.bearingArrow.setSrc("images/compass_arrow.png");
		}
	},
	onKeypress: function(inSender, inEvent){
		if( inEvent.keyCode == 115 ){ // S
			this.owner.owner.$.plugin.movePosition(-0.0001, 0);
		} else if(inEvent.keyCode == 119 ){ // W
			this.owner.owner.$.plugin.movePosition(+0.0001, 0);
		} else if(inEvent.keyCode == 97 ){ // A
			this.owner.owner.$.plugin.movePosition(0, -0.0001);
		} else if(inEvent.keyCode == 100 ){ // D
			this.owner.owner.$.plugin.movePosition(0, +0.0001);
		
		} else if(inEvent.keyCode == 105 ){ // I
			this.owner.owner.$.plugin.movePosition(+0.00001, 0);
		} else if(inEvent.keyCode == 107 ){ // K
			this.owner.owner.$.plugin.movePosition(-0.00001, 0);
		} else if(inEvent.keyCode == 106 ){ // J
			this.owner.owner.$.plugin.movePosition(0, -0.00001);
		} else if(inEvent.keyCode == 108 ){ // L
			this.owner.owner.$.plugin.movePosition(0, +0.00001);
		} else {
			//console.error(inEvent.charCode, inEvent.keyCode);
		}
	},
	compassHandler: function(event) {
		this.$.bearingBackground.applyStyle("-webkit-transform", "rotate(" + -event.trueHeading + "deg)");
		console.error("comapassEvent heading: " + enyo.json.stringify(event.trueHeading));
	},
});
