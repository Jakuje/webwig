enyo.kind({
	name: "WIGApp.CartDetail",
	kind: enyo.VFlexBox,
	events: { 
		onPlay: ""
	},
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Wherigo name"},
			{kind: "Spacer"}
		]},
		{kind: "Scroller", flex: 1, components: [
			{kind: "Item", components: [
				{kind: "Divider", caption: "Author and comapny"},
				{layoutKind: "HFlexLayout", components: [
					{name: "author"}, {kind: "Spacer"}, {name: "company"}
					]},
				{name: "icon", kind: "Divider", caption: "Description"},
				{name: "description", allowHtml: true},
				{kind: "Divider", caption: "Start location"},
				{layoutKind: "HFlexLayout", components: [
					{name: "startLocation", flex: 1},
					{name: "map", kind: "IconButton", icon: "images/locations.png", onclick: "showMap"},
				]},
				{kind: "Divider", caption: "Start location description"},
				{name: "startDescription", allowHtml: true},
				{kind: "Divider", caption: "Type and version"},
				{layoutKind: "HFlexLayout", components: [
					{name: "type"}, {kind: "Spacer"}, {name: "version"}
					]},
				{kind: "Image", name: "splash"}
			]},
				
		]},
		{kind: "Toolbar", layoutKind: "HFlexLayout", components: [
			{caption: "Play", onclick: "playCartridge"},
			{kind: "Spacer"},
			{caption: "Delete", onclick: "deleteCartridge"},
		]},
	],
	create: function(){
		this.inherited(arguments);
	},
	
	data: [],
	setup: function(data){
		this.data = data;
		this.$.title.setContent(data.name);
		if( data.icon ){
			this.$.icon.setIcon( DATA_DIR + "." + data.guid + "/" + data.icon );
		} else {
			this.$.icon.setIcon('');
		}
		if( data.splash ){
			this.$.splash.setSrc( DATA_DIR + "." + data.guid + "/" + data.splash );
		} else {
			this.$.splash.setSrc('');
		}
		this.$.description.setContent(data.description);
		this.$.startDescription.setContent(data.startingLocationDescription);
		if( data.latitude == 360 && data.longitude == 360 ){
			this.$.startLocation.setContent("Anywhere");
			this.$.map.hide();
		} else {
			this.$.startLocation.setContent(data.latitude.toFixed(6) + " " + data.longitude.toFixed(6));
			this.$.map.show();
		}
		this.$.type.setContent(data.type);
		this.$.version.setContent(data.version);
		this.$.author.setContent(data.author);
		this.$.scroller.setScrollTop(0);
		
	},
	
	playCartridge: function(){
		this.doPlay(this.data);
	},
	
	deleteCartridge: function(){
		this.owner.popupMessage( new WIGApp.MessageBox("Do you realy want to delete this cartridge and all stored data (including savegame and logs)",
			"Prompt", "", "Yes", "No",
			function( context, button ){
				if( button == "Button1" ){
					context.$.plugin.deleteCartridge(context.$.cDetail.data.filename);
					context.$.pane.back();
				}
			}) );
	},
	
	showMap: function(inSender, inEvent){
		this.owner.$.mappingTool.call({
			'id': 'de.metaviewsoft.maptool',
			'params': [{
				"name": this.data.name,
				"lat": this.data.latitude,
				"lon": this.data.longitude
			}],
		});
	},
	
	goBack: function(inSender, inEvent){
		this.owner.goBack(inSender, inEvent);
	}
});
