enyo.kind({
	name: "WIGApp.CartDetail",
	kind: enyo.VFlexBox,
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{kind: "Spacer"},
			{name: "title", kind: enyo.VFlexBox, content: "Wherigo name"},
			{kind: "Spacer"},
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
			]},
				
		]},
		{ kind: enyo.ApplicationEvents, onBack: "goBack" }
	],
	create: function(){
		this.inherited(arguments);
	},
	
	setup: function(data){
		this.$.title.setContent(data.name);
		if(data.iconID != "-1"){
			this.$.icon.setIcon(DATA_DIR + data.guid + '_icon.png');
		}
		this.$.description.setContent(data.description);
		this.$.startDescription.setContent(data.startingLocationDescription);
		this.$.type.setContent(data.type);
		this.$.version.setContent(data.version);
		this.$.author.setContent(data.author);
		
	},
	
	goBack: function(inSender, inEvent){
		this.owner.goBack();
		inEvent.stopPropagation();
		inEvent.preventDefault();
	}
});
