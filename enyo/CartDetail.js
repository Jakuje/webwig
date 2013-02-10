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
				{name: "description", layoutKind: "HFlexLayout"},
				{kind: "Divider", caption: "Start location description"},
				{name: "startDescription", layoutKind: "HFlexLayout"},
				{kind: "Divider", caption: "Type and version"},
				{layoutKind: "HFlexLayout", components: [
					{name: "type"}, {kind: "Spacer"}, {name: "version"}
					]},
				{kind: "Image", name: "splash"}
			]},
				
		]},
		{kind: "Toolbar", layoutKind: "HFlexLayout", components: [
			{caption: "Play", onclick: "playCartridge"},
		]},
	],
	create: function(){
		this.inherited(arguments);
	},
	
	data: [],
	setup: function(data){
		this.data = data;
		this.$.title.setContent(data.name);
		if(data.iconID != "-1"){
			this.$.icon.setIcon(CONF_DIR + data.guid + '_icon.png');
		} else {
			this.$.icon.setIcon('');
		}
		if(data.splashID != "-1"){
			this.$.splash.setSrc(CONF_DIR + data.guid + '_splash.png');
		} else {
			this.$.splash.setSrc('');
		}
		this.$.description.setContent(data.description);
		this.$.startDescription.setContent(data.startingLocationDescription);
		this.$.type.setContent(data.type);
		this.$.version.setContent(data.version);
		this.$.author.setContent(data.author);
		
	},
	
	playCartridge: function(){
		this.doPlay(this.data);
	},
	
	goBack: function(inSender, inEvent){
		this.owner.goBack(inSender, inEvent);
	}
});
