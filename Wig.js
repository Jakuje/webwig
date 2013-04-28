const DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
const CONF_DIR = DATA_DIR;
const DEBUG = false;
const PREFS_COOKIE = "appPrefs";

const MAP_MAP_TOOL = 1;
const MAP_HP = 2;
const MAP_GOOGLE = 3;

enyo.kind({
	name: "WIGApp",
	kind: "VFlexBox",
	components: [
		{kind: "WIGApp.Plugin", name: "plugin"},
		{kind: "enyo.Sound", src: "", name: "sound"},
		{
            name : "SysSound",
            kind : "PalmService",
            service : "palm://com.palm.audio/systemsounds",
            method : "playFeedback",
        },
		{name: "pane", kind: "Pane", flex: 1, onSelectView: "viewSelected",
			transitionKind: "enyo.transitions.LeftRightFlyin", components: [
				{name: "Main", className: "enyo-bg", kind: "WIGApp.Main",
					onList: "showList"},
				{name: "cList", className: "enyo-bg", kind: "WIGApp.CartList",
					onInfo: "cartSelected", onPlay: "gameStarted"},
				{name: "cDetail", className: "enyo-bg", kind: "WIGApp.CartDetail",
					onPlay: "gameStarted"},
				{name: "gMain", className: "enyo-bg", kind: "WIGApp.GameMain"},
				{name: "tWaypoint", className: "enyo-bg", kind: "WIGApp.Waypoint"},
				{name: "Preferences", className: "enyo-bg", kind: "WIGApp.Preferences"}
			]
		},
		{kind: "AppMenu", components: [ // In chromium: CTRL + `
			{kind: "EditMenu"},
			{caption: "Preferences", onclick: "showPreferences"},
			{caption: "Refresh", name: "menuRefresh", onclick: "doRefresh"},
			{caption: "Move to Zverokruh", onclick: "tempPostUpdateUI", showing: DEBUG},
			{caption: "Save game", name: "menuSave", onclick: "doSave", showing: false}
			/*{kind: "HelpMenu", target: "http://jakuje.dta3.com"}*/
		]},
		{
			name: "mapTool",
			kind: "PalmService",
			service: "palm://com.palm.applicationManager/",
			method: "launch",
			onFailure: "mapToolFallback",
			onSuccess: "mapSuccess",
		},
		{
			name: "launcher",
			kind: "PalmService",
			service: "palm://com.palm.applicationManager/",
			method: "open",
			onFailure: "mapFailed",
			onSuccess: "mapSuccess",
		},
		{ kind: enyo.ApplicationEvents,
			onBack: "goBack",
			onOpenAppMenu: "onOpenAppMenu"
		},
		{
		   kind: "ModalDialog",
		   name: "errorMessage",
		   caption: "Message",
		   layoutKind: "VFlexLayout",
		   lazy: false,
		   components: [
				{name: "messageScroller", kind: "BasicScroller", autoVertical: true, style: "height: auto;", flex: 1,
					components: [
						{ layoutKind: "VFlexLayout", align: "center", components: [
							{
								name: "media",
								kind: "Image",
								showing: "false"
							},
						]},
						{
							name: "errorText",
							content: "Chyba toho a toho.",
							allowHtml: true,
							className: "",
						},
						{
							name: "getInput",
							kind: "Input",
							showing: false
						},
						{	kind: "VirtualRepeater", name: "choices", onSetupRow: "getChoices", showing: false, components: [
							{kind: "Item", layoutKind: "HFlexLayout", components: [
								{name: "choice", kind: "Button", onclick: "closePopup", flex: 1},
								]}
							]
						}
					]
			   },
				{
					name: "Button1",
					kind: "Button",
					caption: "OK",
					onclick: "closePopup",
				},
				{
					name: "Button2",
					kind: "Button",
					caption: "Cancel",
					onclick: "closePopup",
					showing: "false"
				}
		   ],
		},
		{
			name      : "location",
			kind      : "PalmService",
			service   : "palm://com.palm.location/",
			method    : "startTracking",
			onSuccess : "gotPosition",
			onFailure : "gotPositionError",
			subscribe : true
		},
		{kind: "WIGApp.Utils", name: "utils"},
	],
	

	create: function() {
		this.inherited(arguments);
		//this.$.pane.selectViewByName("cList");
		//this.$.pane.selectViewByName("gMain");
		//this.$.cList.getCartridges(0);
		enyo.setAllowedOrientation( this.getPrefs("orientation") );
	},
	
	openMessage: null,
	popupQueue: [], // push(), shift()
	popupMessage: function( o ){
		/*if( this.$.errorMessage.isOpen && this.openMessage.kindName == "WIGApp.Dialog"
			 && o.kindName == "WIGApp.Dialog"){
			this.popupQueue.push( o );
			return;
		} else*/ if( this.$.errorMessage.isOpen ){
			this.openMessage.hidePopup(this, null, null);
			/*for( item in this.popupQueue){
				item.hidePopup(this, null, null);
			}
			this.popupQueue.length = 0;*/
		}
		this.popupPaint( o );
	},
	popupPaint: function( o ){
		this.openMessage = o;
		o.showPopup(this);
	},
	getChoices: function( inSender, inIndex ){
		if (this.openMessage.choices && inIndex < this.openMessage.choices.length) {
			this.$.choice.setContent( this.openMessage.choices[inIndex] );
			return true;
		}
	},
	closePopup: function(inSender, inEvent) {
		this.openMessage.hidePopup(this, inSender, inEvent);
		
		this.openMessage = null;
		
		if( this.popupQueue.length > 0 ){
			this.popupPaint( this.popupQueue.shift() );
		}
	},
	
	gotPositionError: function(inSender, inResponse){
		//console.error("startTracking failure, results=" + enyo.json.stringify(inResponse));
	},
	gotPosition: function(inSender, inResponse){
		//console.error("startTracking success, results=" + enyo.json.stringify(inResponse));
		if( inResponse.returnValue == true ){
			if( inResponse.errorCode == 0 ){
				this.$.cList.setPosition([inResponse.latitude, inResponse.longitude]);
			}
		}
	},

	viewSelected: function(inSender, inView, inPreviousView) {
		if( inPreviousView.name == "cList"){
			// unsubscribe from location update
			if( window.PalmSystem ){
				this.$.location.cancel();
			}
		}
		if( inView.name == "cList" ){
			// subscribe to update distances in list
			if( window.PalmSystem ){
				this.$.location.call({"subscribe":true});
			} else {
				this.gotPosition(null, {latitude: 49.1, longitude: 16.1, returnValue: true, errorCode: 0} );
			}

		}
			
	},
	
	cartSelected: function(inSender, inMetadata) {
		this.$.pane.selectViewByName("cDetail");
		this.$.cDetail.setup(inMetadata);
	},
	
	showList: function(inSender, type, state, anywhere){
		this.$.cList.setup(type, state, anywhere);
		this.$.pane.selectViewByName("cList");
	},
	
	showPreferences: function(inSender){
		this.$.Preferences.setup();
		this.$.pane.selectViewByName("Preferences");
	},
	
	gameStarted: function(inSender, inMetadata){
		//this.$.pane.selectViewByName("gMain");
		if( inMetadata.saved ){
			this.popupMessage( new WIGApp.MessageBox("There is saved game in working direcotry. Do you want to continue?", "Prompt", "", "Yes", "No",
				function(context, button){
					context.$.gMain.prepare(inMetadata, ( button == "Button1" ? 1 : 0) );
				}
			));
		} else {
			this.$.gMain.prepare(inMetadata, 0 );
		}
	},
	
	onOpenAppMenu: function(inSender, inEvent) {
		if (this.$.pane.getViewName() == "gMain") {
			this.$.menuRefresh.hide();
			this.$.menuSave.show();
		} else {
			this.$.menuRefresh.show();
			this.$.menuSave.hide();
		}
	},
	
	// handler for Back Swipe (ESC for Emulator / Chrome)
	// and propagated from gamePane (gMain)
	goBack: function(inSender, inEvent, force) {
		console.log("back");
		inEvent.stopPropagation();

		// we are on home page and we want to go to card view
		if( this.$.pane.getViewName() !=  "cList" ){
			inEvent.preventDefault();
		}

		if( this.$.pane.getViewName() ==  "gMain" ){
			if( ! force ){
				this.$.gMain.goBack(inSender, inEvent);
			} else {
				// @todo Prompt and in case OK => goBack directly
				this.popupMessage( new WIGApp.MessageBox("Do you really want to exit game without saving?", "Prompt", "", "OK", "Cancel",
					// if OK then close cartridge (cleanup and close game pane)
					function( context, button ){
						if( button == "Button1" ){
							context.$.plugin.closeCartridge(0);
							context.$.pane.back();
						}
						}) );
			}
			return false;
		}
		
		this.$.pane.back(inEvent);
	},
	
	tempPostUpdateUI: function(){
		/*enyo.nextTick(this, function() { this.$.gMain.updateUI(
			{ "locations": [{"name": "Zona 42", "description": "", "distance": 48960.724432131},{"name": "Zone another", "description": "", "distance": 51575.499790582}], "youSee": [], "inventory": [{"name": "Věc", "description": "S obrazkem a ikonkou", "media": "/media/internal/appdata/com.dta3team.app.wherigo/2ca1f78e-9c75-4d69-8cf0-7bd0b4576b7a/2.png", "icon": "/media/internal/appdata/com.dta3team.app.wherigo/2ca1f78e-9c75-4d69-8cf0-7bd0b4576b7a/3.png"}], "tasks": [{"name": "Ukol", "description": "Udelej to a to.", "id": "11", "media": "/media/internal/appdata/com.dta3team.app.wherigo/2ca1f78e-9c75-4d69-8cf0-7bd0b4576b7a/1.jpg", "icon": "/media/internal/appdata/com.dta3team.app.wherigo/2ca1f78e-9c75-4d69-8cf0-7bd0b4576b7a/3.png", "onclick": true},{"name": "Another task", "description": "", "id": "12", "icon": "/media/internal/appdata/com.dta3team.app.wherigo/2ca1f78e-9c75-4d69-8cf0-7bd0b4576b7a/3.png"}], "gps": 2}
			);
		});*/
		this.$.plugin.setPosition(49.223878820512, 16.529799699783);
		//this.$.plugin.setPosition(49.227367,16.62254);
		//this.$.plugin.setPosition(49.227095,16.625119);
	},
	doSave: function(){
		this.$.plugin.save();
	},
	doRefresh: function(){
		this.$.cList.refreshClicked();
	},
	
	tmp_params: null,
	showMap: function( params ){
		switch( this.getPrefs("map") ){
			case MAP_MAP_TOOL:
				this.$.mapTool.onFailure = "mapToolFallback";
				tmp_params = params;
				this.$.mapTool.call({
					'id': 'de.metaviewsoft.maptoolpro',
					'params': params,
				});
				break;
			case MAP_HP:
				var lat = 0;
				var lon = 0;
				for( i in params ){
					lat += params[i].lat;
					lon += params[i].lon;
				}
				lat = lat / params.length;
				lon = lon / params.length;
				this.$.launcher.call({
					'id': 'com.palm.app.maps',
					'params': {
						"query": lat + " " + lon,
						"zoom": "17"
					},
				});
				break;
			case MAP_GOOGLE:
				var lat = 0;
				var lon = 0;
				for( i in params ){
					lat += params[i].lat;
					lon += params[i].lon;
				}
				lat = lat / params.length;
				lon = lon / params.length;
				var dest = "http://maps.google.com/?q=" + lat + "%20" + lon;
				this.$.launcher.call({
					"id": "com.palm.app.browser",
					'params': {
						"target": dest,
					},
				});
				break;
			default:
				this.popupMessage( new WIGApp.Dialog("No mapping app specified. Please choose one in preferences.", "Error") );
				break;
		}
	},
	mapToolFallback: function(inSender, inResponse){
		console.error("map failde, results=" + enyo.json.stringify(inResponse));
		this.$.mapTool.onFailure = this.mapFailed;
		this.$.mapTool.call({
			'id': 'de.metaviewsoft.maptool',
			'params': tmp_params,
		});
	},
	mapFailed: function(inSender, inResponse){
		this.popupMessage( new WIGApp.Dialog("Failed to open Mapping app. Not installed?", "Error") );
		//console.error("map failde, results=" + enyo.json.stringify(inResponse));
	},
	mapSuccess: function(inSender, inResponse){
		console.error("map success, results=" + enyo.json.stringify(inResponse));
	},
	
	prefs: null,
	default_prefs: {"gps": true, "compass": 1, "units": true, "type": "All", "state": "All", "lat": "49", "lon": "16", "map": MAP_MAP_TOOL, "orientation": "up"},
	getPrefs: function(key){
		if( !this.prefs ){
			try {
				this.prefs = enyo.json.parse( enyo.getCookie(PREFS_COOKIE) );
			} catch(err) {
				this.prefs = this.default_prefs;
				this.setPrefs();
			}
		}
		if( typeof this.prefs[key] != 'undefined' ){
			return this.prefs[key];
		} else {
			return this.default_prefs[key];
		}
	},
	setPrefs: function(key, value){
		if( key ){
			if( key == "orientation" ){
				enyo.setAllowedOrientation( value );
			}
			this.prefs[key] = value;
		}
		enyo.setCookie(PREFS_COOKIE, enyo.json.stringify(this.prefs));
	},
	showTools: function(what){
		this.$.pane.selectViewByName(what);
	}
});
