/**
 * result from backend
 * {type = error, message = chyba}
 * {type = ok, data = [...]}
 */

enyo.kind({
  name: "WIGApp.Plugin",
  kind: "enyo.Hybrid",
  executable: "wig",

	create: function() {
		this.inherited(arguments);
		// we create this as a deferred callback so we can call back into the
		// plugin immediately
		this.addCallback("getCartridgesResult", enyo.bind(this, this._getMetaCallback), true);
		this.addCallback("openCartridgeResult", enyo.bind(this, this.openCartridgeResult), true);
		
		this.addCallback("popupMessage", enyo.bind(this, this.messageBox), true);
		this.addCallback("playAudio", enyo.bind(this, this.playAudio), true);
		this.addCallback("GetInput", enyo.bind(this, this.getInput), true);
		this.addCallback("ShowStatusText", enyo.bind(this, this.ShowStatusText), true);
		this.owner.$.plugin.addCallback("updateState",
			enyo.bind(this, this.updateUI), true);
	},
	tmpdir: null,
	
	playAudio: function(media){
		console.error("***** WIG Enyo: playAudio: " + media);
		this.owner.$.sound.setSrc(media);
		this.owner.$.sound.play();
	},
	messageBox: function(message, media, button1, button2, callback){
		console.error("***** WIG Enyo: messageBox:" + message + "b:" + button1 + ", " + button2 + " m:" + media + " c:" + callback);
		if( media ){
			console.error("***** WIG Enyo: Media url: " + media);
		}
		this.owner.popupMessage(message, "Message", media, button1, button2, (callback == "1"));
	},
	MessageBoxResponse: function( value ){
		console.error("***** WIG Enyo: MessageBoxResponse value: " + value);
		if ( window.PalmSystem) {
			this.callPluginMethodDeferred(enyo.nop, "MessageBoxResponse", value);
		}
		
	},
	getInput: function(type, text){
		console.error("***** WIG Enyo: getInput: type" + type + " text:" + text);
		/*if( media ){
			//path = this.tmpdir + "/" + media;
			console.error("***** WIG Enyo: Media url: " + media);
			// not alowed to load local resource
		} else {
			path = false;
		}*/
		//this.owner.popupMessage(text, "Message", media, button1, button2, callback);
		// @todo
	},
	ShowStatusText: function(text){
		enyo.windows.addBannerMessage(text, "{}");
	},
	updateUI: function( JSONdata ){
		console.error(JSONdata);
		result = enyo.json.parse(JSONdata);
		if(result.type == "ok") {
			console.error("***** WIG Enyo: UpdateUI ok ...", JSONdata);
			this.owner.$.gMain.updateUI(result.data);
		} else if( result.type == "error" ){
			console.error("***** WIG Enyo: UpdateUI failed ...");
			this.owner.popupMessage(result.message);
			//enyo.windows.addBannerMessage(result.message, "{}");
		} else {
			console.error("***** WIG Enyo: Unknown result of updateUI");
		}
	},
	_resultsCallbacks: [],
	_getMetaCallback: function(filesJSON) {
		console.error("***** WIG Enyo: _getMetaCallback");
		// we rely on the fact that calls to the plugin will result in callbacks happening
		// in the order that the calls were made to do a first-in, first-out queue
		var callback = this._resultsCallbacks.shift();
		if (callback) {
			console.error(filesJSON);
			result = enyo.json.parse(filesJSON);
			if(result.type == "ok") {
				callback(result.data);
			} else if( result.type == "error" ){
				console.error("***** WIG Enyo: Result failed ...");
				this.owner.popupMessage(result.message);
				enyo.windows.addBannerMessage(result.message, "{}");
			} else {
				console.error("***** WIG Enyo: Unknown result of getMetaCallback");
			}
		}
		else {
			console.error("WIG Enyo: got results with no callbacks registered: " + filesJSON);
		}
	},
	openCartridgeResult: function(JSONdata){
		console.error(JSONdata);
		result = enyo.json.parse(JSONdata);
		if(result.type == "ok") {
			//this.tmpdir = result.data.tmpdir;
			this.owner.$.pane.selectViewByName("gMain");
		} else if( result.type == "error" ){
			console.error("***** WIG Enyo: Open failed ...");
			this.owner.popupMessage(result.message);
			//enyo.windows.addBannerMessage(result.message, "{}");
		} else {
			console.error("***** WIG Enyo: Unknown result of getMetaCallback");
		}
	},
	
	getCartridges: function(refresh, callback) {
		if ( window.PalmSystem) {
			console.error("***** WIG Enyo: getCartridges refresh = " + refresh);
			this._resultsCallbacks.push(callback);
			this.callPluginMethodDeferred(enyo.nop, "getCartridges", refresh);
		}
		else {
			// if not on device, return mock data
			enyo.nextTick(this, function() { callback([
        {
            "filename": "mp.gwc",
            "iconID": "28",
            "type": "Geocache",
            "name": "Monty Python a Svaty Gral",
            "guid": "9680e562-caf2-455e-a095-654b67d8080e",
            "description": "Stan se na chvili kralem Artusem a prijmi jeho poslani najit Svaty gral. Cesta to nebude jednoducha. Tvuj verny sluha Patynka a dalsi udatni rytiri kulateho stolu Ti vsak pomohou. Kdo videl film \"Monty Python and the Holy Grail\" bude mit cestu snazsi a hlavne mnohem zazivnejsi.",
            "startingLocationDescription": "Pobl?? zast?vky MHD N?m. 28. dubna. V noci pak jezd? do Bystrce no?n? autobusov? spoje.",
            "version": "1.2",
            "author": "Karbanatek"
        },
        {
            "filename": "wherigo.lua.gwc",
            "iconID": "-1",
            "type": "",
            "name": "Ahoj Svete",
            "guid": "97e8dd40-78a6-4ae1-9575-6260ff64bdc5",
            "description": "",
            "startingLocationDescription": "",
            "version": "0",
            "author": ""
        }
			]);
			});
		}
	},
	openCartridge: function(filename, callback){
		if ( window.PalmSystem) {
			console.error("***** WIG Enyo: openCartridge filename = " + filename);
			//this._resultsCallbacks.push(callback);
			this.callPluginMethodDeferred(enyo.nop, "openCartridge", filename);
		} else {
			enyo.nextTick(this, function() { this.openCartridgeResult( "{\"type\": \"ok\", \"data\": {}}");
			});
			enyo.nextTick(this, function() { this.owner.$.gMain.updateUI(
			{
					"locations": [{"name": "Somewhere"}],
					"youSee": [],
					"inventory": [{"name": "Something"}, {"name": "Pen"}],
					"tasks": [{"name": "To do something"}],
			}
				);
			});
		}
	},
	closeCartridge: function(save, callback){
		if ( window.PalmSystem) {
			console.error("***** WIG Enyo: closeCartridge save = " + save);
			this._resultsCallbacks.push(callback);
			this.callPluginMethodDeferred(enyo.nop, "closeCartridge", save);
		}
	},
});
