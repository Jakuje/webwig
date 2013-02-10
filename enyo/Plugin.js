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
		this.addCallback("getMetadataResult", enyo.bind(this, this._getMetaCallback), true);
		this.addCallback("getCartridgesResult", enyo.bind(this, this._getMetaCallback), true);
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
				enyo.windows.addBannerMessage(result.message, "{}");
			} else {
				console.error("***** WIG Enyo: Unknown result of getMetaCallback");
			}
		}
		else {
			console.error("WIG Enyo: got results with no callbacks registered: " + filesJSON);
		}
	},
	
	getMetadata: function(cartridge, callback) {
		if ( window.PalmSystem) {
			console.error("***** WIG Enyo: getFiles " + cartridge);
			this._resultsCallbacks.push(callback);
			this.callPluginMethodDeferred(enyo.nop, "getMetadata", cartridge);
		}
		else {
			// if not on device, return mock data
			enyo.nextTick(this, function() { callback([
					{ name: "Moje prvni cartridge", filename: "wherigo.gwc", iconID: "28", type: "geocache", author: "jakuje", description: "sjovhnaiphv uiah uiah vuiah iuah aiuhiuah asuih viuah viou" }
				]); });
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
	}

});
