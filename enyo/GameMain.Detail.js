function arrays_equal(a,b) { return !(a<b || b<a); }

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
			{ name: "bearingBackground", style: "background: transparent url('images/compass_bg.png') center center no-repeat;", components: [
				{name: "bearingArrow", kind: "Image", src: "images/compass_arrow.png"},
				]},
			{ kind: "VFlexBox", components: [
				{name: "distance"},
				{content: "Map", kind: "Button", onclick: "showMappingTool"},
				{kind: "Spacer"},
				{kind: "Button", onclick: "moveTo", content: "Move To", showing: DEBUG},
			]},
			{ kind: "Input", onkeypress: "onKeypress", autoCapitalize: "lowercase", showing: DEBUG}
		]},
		],
	screen: null,
	data: [],
	setup: function(screen, data){
		this.screen = screen;
		var render = false;
		//console.error( (data.id != this.data.id) + " " + (data.media != this.data.media) + " " + (data.name != this.data.name) + " " + !arrays_equal(data.commands, this.data.commands) );
		if( data.id != this.data.id || data.media != this.data.media || data.name != this.data.name ){
			 //|| !arrays_equal(data.commands, this.data.commands)
			 render = true;
		}
		for(var i in this.data.commands ){
			if( !data.commands[i] || this.data.commands[i].id != data.commands[i].id
				|| this.data.commands[i].text != data.commands[i].text ){
					render = true;
			}
		 }
		this.data = data;
		this.$.title.setContent( this.owner.$.gList.$.detail.getTitle(screen) + ": " + data.name );
		this.$.description.setContent( data.description );
		if( data.media ) {
			this.$.image.setSrc( this.owner.details.cartDir + data.media );
			this.$.image.show();
		} else {
			this.$.image.hide();
		}
		if( this.screen == "locations" || (this.screen == "youSee" && data.distance) ){
			if( data.distance < 1500 ){
				this.$.distance.setContent(Math.round(data.distance) + " m");
			} else {
				this.$.distance.setContent(Math.round(data.distance/1000) + " km");
			}
			this.$.bearingBackground.applyStyle("-webkit-transform", "rotate(" + -this.owner.data.gps.heading + "deg)");
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
		
	},
	
	updateUI: function(data){
		if( ! data || this.data.id != data.id ){
			this.owner.goBack();
			return;
		}
		this.setup( this.screen, data );
	},
	
	getCommand: function(inSender, inIndex){
		if (this.data.commands && inIndex < this.data.commands.length) {
			this.$.action.setContent(this.data.commands[inIndex].text);
			return true;
		}
	},
	executeCommand: function(inSender, inEvent){
		event = "On" + this.data.commands[inEvent.rowIndex].id;
		this.owner.owner.$.plugin.callback(event, this.data.id)
	},
	moveTo: function(){
		if( this.screen == "locations"){
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
			this.owner.owner.popupMessage( new WIGApp.Dialog(inEvent.keyCode, "Message"));
			console.error(inEvent.charCode, inEvent.keyCode);
		}
	}
});
