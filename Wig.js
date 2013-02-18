const DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
const CONF_DIR = DATA_DIR;

enyo.kind({
	name: "WIGApp",
	kind: "VFlexBox",
	components: [
		{kind: "WIGApp.Plugin", name: "plugin"},
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
		   caption: "Error",
		   lazy: false,
		   components: [
				{
					name: "errorText",
					content: "Chyba toho a toho.",
					className: "enyo-text-error warning-icon"
				},
				{
					kind: "Button",
					caption: "OK",
					onclick: "closePopup",
				}
		   ]
		}
	],
	

	create: function() {
		this.inherited(arguments);
		//this.$.pane.selectViewByName("cList");
		//this.$.pane.selectViewByName("gMain");
	},
	
	popupMessage: function(message){
		this.$.errorText.setContent(message);
		this.$.errorMessage.openAtCenter();
	},
	closePopup: function(inSender, inEvent) {
		this.$.errorMessage.close();
	},
	
	cartSelected: function(inSender, inMetadata) {
		this.$.pane.selectViewByName("cDetail");
		this.$.cDetail.setup(inMetadata);
	},
	
	gameStarted: function(inSender, inMetadata){
		this.$.pane.selectViewByName("gMain");
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
		inEvent.stopPropagation();
		if( this.$.pane.getViewName() !=  "cList" ){
			inEvent.preventDefault();
		}
		this.$.pane.back(inEvent);
	}
});
