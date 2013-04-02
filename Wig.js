const DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
const CONF_DIR = DATA_DIR;

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
			components: [
				{name: "cList", className: "enyo-bg", kind: "WIGApp.CartList",
					onInfo: "cartSelected", onPlay: "gameStarted"},
				{name: "cDetail", className: "enyo-bg", kind: "WIGApp.CartDetail",
					onPlay: "gameStarted"},
				{name: "gMain", className: "enyo-bg", kind: "WIGApp.GameMain"}
			]
		},
		{kind: "AppMenu", components: [ // In chromium: CTRL + `
			{kind: "EditMenu"},
			{caption: "Preferences", onclick: "turnLightsOff"},
			{caption: "Refresh", name: "menuRefresh", onclick: "doRefresh", kind: "AppMenuItem"},
			{caption: "Move to Zverokruh", onclick: "tempPostUpdateUI"},
			{caption: "Save game", name: "menuSave", onclick: "doSave", showing: false, kind: "enyo.AppMenuItem"}
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
				{kind: "BasicScroller", autoVertical: true, style: "height: auto;",
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
		   }],
	

	create: function() {
		this.inherited(arguments);
		//this.$.pane.selectViewByName("cList");
		//this.$.pane.selectViewByName("gMain");
		//this.$.cList.getCartridges(0);
		enyo.setAllowedOrientation("up");
	},
	
	openMessage: null,
	popupQueue: [], // push(), shift()
	popupMessage: function( o ){
		if( this.$.errorMessage.isOpen && this.openMessage.kindName == "WIGApp.Dialog"
			 && o.kindName == "WIGApp.Dialog"){
			this.popupQueue.push( o );
			return;
		} else if( this.$.errorMessage.isOpen ){
			this.openMessage.hidePopup(this, null, null);
			for( item in this.popupQueue){
				item.hidePopup(this, null, null);
			}
			this.popupQueue.length = 0;
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
	
	cartSelected: function(inSender, inMetadata) {
		this.$.pane.selectViewByName("cDetail");
		this.$.cDetail.setup(inMetadata);
	},
	
	gameStarted: function(inSender, inMetadata){
		//this.$.pane.selectViewByName("gMain");
		if( inMetadata.saved ){
			this.popupMessage( new WIGApp.MessageBox("There is saved game in working direcotry. Do you want to continue?", "Prompt", "", "Yes", "No",
				function(context, button){
					context.$.gMain.setup(inMetadata, ( button == "Button1" ? 1 : 0) );
				}
			));
		} else {
			this.$.gMain.setup(inMetadata, 0 );
		}
	},
	
	viewSelected: function(inSender, inView) {
		if (inView == this.$.gMain) {
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
	}
});
