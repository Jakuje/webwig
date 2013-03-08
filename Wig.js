const DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
const CONF_DIR = DATA_DIR;

enyo.kind({
	name: "WIGApp",
	kind: "VFlexBox",
	components: [
		{kind: "WIGApp.Plugin", name: "plugin"},
		{kind: "enyo.Sound", src: "", name: "sound"},
		{name: "pane", kind: "Pane", flex: 1, onSelectView: "viewSelected",
			components: [
				{name: "cList", className: "enyo-bg", kind: "WIGApp.CartList",
					onInfo: "cartSelected", onPlay: "gameStarted"},
				{name: "cDetail", className: "enyo-bg", kind: "WIGApp.CartDetail",
					onPlay: "gameStarted"},
				{name: "gMain", className: "enyo-bg", kind: "WIGApp.GameMain"}
			]
		},
		{kind: "AppMenu", components: [
			{kind: "EditMenu"},
			{caption: "Preferences", onclick: "turnLightsOff"},
			{caption: "Refresh", onclick: "turnLightsOn"},
			{caption: "Move to next Zone", onclick: "tempPostUpdateUI"},
			/*{kind: "HelpMenu", target: "http://jakuje.dta3.com"}*/
		]},
		{ kind: enyo.ApplicationEvents, onBack: "goBack" },
		{
		   kind: "ModalDialog",
		   name: "errorMessage",
		   caption: "Message",
		   layoutKind: "VFlexLayout",
		   lazy: false,
		   components: [
				{kind: "BasicScroller", autoVertical: true, style: "height: auto;", flex: 1, 
					components: [{
							name: "media",
							kind: "Image",
							showing: "false"
						},
						{
							name: "errorText",
							content: "Chyba toho a toho.",
							allowHtml: true,
							className: "",
						},
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
		   }],
	

	create: function() {
		this.inherited(arguments);
		//this.$.pane.selectViewByName("cList");
		//this.$.pane.selectViewByName("gMain");
		//this.$.cList.getCartridges(0);
	},
	
	popupCallback: false,
	popupQueue: [], // push(), shift()
	popupMessage: function(message, title, media, button1, button2, callback){
		if( this.$.errorMessage.isOpen ){
			this.popupQueue.push([message, title, media, button1, button2, callback]);
			return;
		}
		this.popupPaint([message, title, media, button1, button2, callback]);
	},
	popupPaint: function( array ){
		message = array[0];
		title = array[1];
		media = array[2];
		button1 = array[3];
		button2 = array[4];
		callback = array[5];
		
		if( title ){
			this.$.errorMessage.setCaption(title);
		} else {
			this.$.errorMessage.setCaption("Error");
			this.$.errorMessage.setClassName("enyo-text-error");
		}
		this.$.errorText.setContent(message);
		if( media && media != "" ){
			this.$.media.setSrc(media);
			this.$.media.show();
		} else {
			this.$.media.hide();
		}
		if( button1 ){
			this.$.Button1.setCaption(button1);
		} else {
			this.$.Button1.setCaption("OK");
		}
		if( button2 ){
			this.$.Button2.setCaption(button2);
			this.$.Button2.show();
		} else {
			this.$.Button2.hide()
		}
		this.popupCallback = callback;
		
		this.$.errorMessage.openAtCenter();
	},
	closePopup: function(inSender, inEvent) {
		this.$.errorMessage.close();
		
		// internal usage, JS function is callback
		if( typeof this.popupCallback == "function" ){
			this.popupCallback( inSender.getName() );
		} else if( this.popupCallback == true ){
			this.$.plugin.MessageBoxResponse(inSender.getName());
		}
		
		if( this.popupQueue.length > 0 ){
			this.popupPaint( this.popupQueue.shift() );
		}
	},
	
	cartSelected: function(inSender, inMetadata) {
		this.$.pane.selectViewByName("cDetail");
		this.$.cDetail.setup(inMetadata);
	},
	
	gameStarted: function(inSender, inMetadata){
		//this.$.pane.selectViewByName("gMain");
		this.$.gMain.setup(inMetadata);
	},
	
	viewSelected: function(inSender, inView) {
		if (inView == this.$.cList) {
			// ??
		} else if (inView == this.$.cDetail) {
			// ??
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
				this.popupMessage("Do you really want to exit game without saving?", "Prompt", "", "OK", "Cancel",
					// if OK then close cartridge (cleanup and close game pane)
					function( button ){
						if( button == "Button1" ){
							this.$.plugin.closeCartridge(1);
							this.$.pane.back();
						}
						});
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
	}
});
