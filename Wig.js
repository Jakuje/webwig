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
		console.log("Callback: ", callback);
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
		if( media ){
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
		if( this.popupCallback ){
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

	goBack: function(inSender, inEvent) {
		console.log("back");
		inEvent.stopPropagation();
		if( this.$.pane.getViewName() ==  "gMain" ){
			// @todo Prompt and in case OK => goBack directly
			this.popupMessage("Do you really want to exit game without saving?", "Prompt");
			//return false;
			this.$.plugin.closeCartridge(1);
		}
		
		if( this.$.pane.getViewName() !=  "cList" ){
			inEvent.preventDefault();
		}
		this.$.pane.back(inEvent);
	}
});
