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
			},
			{kind: "VirtualRepeater", name: "commands", onSetupRow: "getCommand", components: [
				{kind: "Item", layoutKind: "HFlexLayout", components: [
					{name: "action", kind: "Button", onclick: "executeCommand", flex: 1},
					]}
				]},
			]
		},
		{kind: "HFlexBox", name: "distanceBox", showing: false, components: [
			{name: "distance", flex: 1},
			{kind: "Button", onclick: "moveTo"},
			{name: "bearing", flex: 1},
			{content: "MT", kind: "Button", flex: 1, onclick: "showMappingTool"},
		]},
		{
			name: "mappingTool",
			kind: "PalmService",
			service: "palm://com.palm.applicationManager",
			method: "launch",
			onFailure: "mappingToolFailed"
		}
		],
	screen: null,
	data: [],
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
		this.render();
		if( this.screen == "locations" ){
			if( data.distance < 2000 ){
				this.$.distance.setContent(Math.round(data.distance) + " m");
			} else {
				this.$.distance.setContent(Math.round(data.distance/1000) + " km");
			}
			this.$.bearing.setContent(Math.round(data.bearing) + "°");
			this.$.distanceBox.show();
		} else {
			this.$.distanceBox.hide();
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
		this.$.mappingTool.call({
			'id': 'de.metaviewsoft.maptool',
			'params': enyo.json.stringify( [{
				'lat': this.data.lat,
				'lon': this.data.lon,
				'name': this.data.name,
				}] )
		});
	},
	mappingToolFailed: function(){
		this.owner.owner.popupMessage( new WIGApp.Dialog("Failed to open Mapping Tool", "Error") );
	}
});
