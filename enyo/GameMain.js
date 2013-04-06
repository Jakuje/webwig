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
			{layoutKind: "VFlexLayout", flex: 1, align: "center", components: [
				{name: "title", content: "Wherigo name"},
				{name: "subtitle", content: "&nbsp;", className: "enyo-item-secondary"},
				]},
			{kind: "Image", name: "GPSAccuracy", src: "images/gps_0.png", onclick: "showDashboard"},
		]},
		{kind: "PageHeader", showing: false, name: "dashboard", components: [
			{content: "Accuracy:&nbsp;"},
			{name: "accuracy", content: "3 m"},
			{kind: "Spacer"},
			{name: "GPSStatus", kind: "ToggleButton", onChange: "switchGPS"}
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
	details: [],
	create: function(){
		this.inherited(arguments);
	},
	
	prepare: function(data, load_game){
		this.$.title.setContent( data.name.substring(0, 20) + (data.name.length > 20 ? "..." : "") );
		this.owner.$.plugin.openCartridge(data.filename, load_game, enyo.nop);
	},
	
	setup: function(data){
		this.details = data;
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
		var acc = data.gps.acc;
		var acc_class = 0;
		if( acc < 0 || acc > 1000 ){
			acc_class = 0;
		} else if( acc > 100 ){
			acc_class = 1;
		} else  if( acc > 50 ){
			acc_class = 2;
		} else if( acc > 20 ){
			acc_class = 3;
		} else {
			acc_class = 4;
		}
		this.$.GPSAccuracy.setSrc("images/gps_"+acc_class+".png");
		this.$.accuracy.setContent(acc + " m");
		this.$.GPSStatus.setState(data.gps.state);
	},
	detail_item: 0,
	detail_screen: "",
	showScreenLua: function(screen, item){
		if( screen != this.DETAILSCREEN && screen != this.MAINSCREEN
			&& this.detail_screen != this.DETAILSCREEN && this.detail_screen == this.MAINSCREEN){
			// List screen => List screen - Just repaint
				this.showScreen(screen);
				return;
		} else if ( screen == this.DETAILSCREEN && this.detail_item != null ){
			for( var scr in this.data ){
				for( var it in this.data[scr] ){
					if( this.data[scr][it].id == item ){
						if( scr == this.detail_screen && it == this.detail_item){
							// Detail => Detail with same id => Just repaint
							this.showScreen(scr, it);
							return;
						}
					}
				}
			}
		}
		// everything else
		
		// go home
		while( this.$.pane.getViewName() != "gMain" ){
			this.goBack();
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
			this.detail_item = null;
			this.$.gList.setup(screen, this.data);
			this.$.subtitle.setContent(this.$.gList.$.detail.getTitle(screen));
			this.$.pane.selectViewByName("gList");
		} else {
			this.detail_item = item;
			this.$.gDetail.setup(screen, this.data[screen][item]);
			this.$.subtitle.setContent(this.$.gList.$.detail.getTitle(screen) + ": " + this.data[screen][item].name);
			this.$.pane.selectViewByName("gDetail");
		}
	},
	
	goBack: function(inSender, inEvent){
		if( this.$.pane.getViewName() ==  "gMain" ){
			this.owner.goBack(inSender, inEvent, true);
		} else {
			this.$.pane.back(inEvent);
			if( this.$.pane.getViewName() == "gList" ){
				this.$.subtitle.setContent( this.$.gList.$.detail.getTitle(this.detail_screen) );
			} else {
				this.$.subtitle.setContent("&nbsp;");
			}
		}
	},
	showDashboard: function(){
		if( this.$.dashboard.showing ){
			this.$.dashboard.hide();
		} else {
			this.$.dashboard.show();
		}
	},
	switchGPS: function(inSender, inEvent){
		if( this.data['gps']['state'] != inEvent ){
			this.owner.$.plugin.switchGPS( Number(inEvent) );
		}
	}
});
