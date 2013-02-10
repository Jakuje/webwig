const DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";

enyo.kind({
	name: "WIGApp",
	kind: "VFlexBox",
	components: [
		{kind: "WIGApp.Plugin", name: "plugin"},
		{name: "pane", kind: "Pane", flex: 1, onSelectView: "viewSelected",
			components: [
				{name: "cList", className: "enyo-bg", kind: "WIGApp.CartList",
					onSelect: "cartSelected"},
				{name: "cDetail", className: "enyo-bg", kind: "WIGApp.CartDetail"}
			]
		},
      {kind: "AppMenu", components: [
			{kind: "EditMenu"},
			{caption: "Preferences", onclick: "turnLightsOff"},
			{caption: "Refresh", onclick: "turnLightsOn"},
			{kind: "HelpMenu", target: "http://jakuje.dta3.com"}
		]}
	],
	

	create: function() {
		this.inherited(arguments);
		this.$.pane.selectViewByName("cList");
	},
	
	cartSelected: function(inSender, inMetadata) {
		this.$.pane.selectViewByName("cDetail");
		this.$.cDetail.setup(inMetadata);
	},
	
	viewSelected: function(inSender, inView) {
		if (inView == this.$.cList) {
			// ??
		} else if (inView == this.$.detail) {
			// ??
		}
	},

	goBack: function(inSender, inEvent) {
		this.$.pane.back(inEvent);
	}
});
