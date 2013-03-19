enyo.kind({
	// screens constants
	MAINSCREEN			: "main",
	INVENTORYSCREEN 	: "inventory",
	ITEMSCREEN 			: "youSee",
	LOCATIONSCREEN		: "locations",
	TASKSCREEN			: "tasks",
	DETAILSCREEN 		: "detail",

	name: "WIGApp.GameMain",
	kind: enyo.VFlexBox,
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Wherigo name"},
			{kind: "Spacer"},
			{kind: "Image", name: "GPSState", src: "images/gps_0.png"},
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
		if( typeof data.locations != 'undefined' ){
			//console.error("Writing all ...");
			this.data = data;
			this.$.gMain.updateUI(data);
			if( this.$.pane.getViewName() != "gMain" ){
				this.$.gList.updateUI(data);
				if( this.$.pane.getViewName() == "gDetail" ){
					this.$.gDetail.updateUI(data[this.detail_screen][this.detail_item]);
				}
			}
		} else {
			//console.error("Only GPS data");
			this.data.gps = data.gps;
		}
		this.$.GPSState.setSrc("images/gps_"+data.gps+".png");
	},
	detail_item: 0,
	detail_screen: "",
	showScreenLua: function(screen, item){
		// go home
		while( this.$.pane.getViewName() != "gMain" ){
			this.goBack()
		}
		if( screen != this.MAINSCREEN ){
			if( screen == this.DETAILSCREEN ){
				for( var scr in this.data ){
					for( var it in this.data[scr] ){
						if( this.data[scr][it].id == item ){
							this.showScreen(scr, it);
						}
					}
				}
			} else {
				this.showScreen(screen);
			}
		}
	},
	showScreen: function(screen, item){
		this.detail_screen = screen;
		if( item == undefined ){
			this.$.gList.setup(screen, this.data);
			this.$.pane.selectViewByName("gList");
		} else {
			this.detail_item = item;
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
	}
});
