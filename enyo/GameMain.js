enyo.kind({
	name: "WIGApp.GameMain",
	kind: enyo.VFlexBox,
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Wherigo name"},
			{kind: "Spacer"}
		]},
		{name: "pane", kind: "Pane", flex: 1,
			components: [
				{name: "gMain", className: "enyo-bg", kind: "WIGApp.GameMain.HomeScreen"},
				{name: "gList", className: "enyo-bg", kind: "WIGApp.GameMain.List"},
				{name: "gDetail", className: "enyo-bg", kind: "WIGApp.GameMain.Detail"}
			]
		},
	],
	data: [],
	create: function(){
		this.inherited(arguments);
	},
	
	setup: function(data){
		this.$.title.setContent(data.name);
		this.owner.$.plugin.openCartridge(data.filename, enyo.nop);
	},
	
	updateUI: function(data){
		this.data = data;
		if( this.$.pane.getViewName() ==  "gMain" ){
			this.$.gMain.updateUI(data);
		} else {
			this.$.gList.updateUI(data);
		}
	},
	showScreen: function(screen, item){
		if( item == undefined ){
			this.$.gList.setup(screen, this.data);
			this.$.pane.selectViewByName("gList");
		} else {
			this.$.gDetail.setup(screen, this.data[screen][item]);
			this.$.pane.selectViewByName("gDetail");
		}
	},
	
	goBack: function(inSender, inEvent){
		if( this.$.pane.getViewName() ==  "gMain" ){
			this.owner.goBack(inSender, inEvent, true);
		} else {
			this.$.pane.back(inEvent);
		}
		// todo: Back swipe
	}
});
