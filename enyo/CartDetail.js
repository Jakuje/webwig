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
				{kind: "Divider", caption: "Description"},
				{name: "description", layoutKind: "HFlexLayout"},
				{kind: "Divider", caption: "Start location description"},
				{name: "startDescription", layoutKind: "HFlexLayout"},
				{kind: "Divider", caption: "Author and version"},
				{layoutKind: "HFlexLayout", components: [
					{name: "author"}, {kind: "Spacer"}, {name: "version"}
					]},
				]}
		]},
		{ kind: enyo.ApplicationEvents, onBack: "goBack" }
	],
	create: function(){
		this.inherited(arguments);
	},
	
	setup: function(metadata){
		this.$.title.setContent(metadata.name);
		this.$.description.setContent(metadata.description);
		this.$.startDescription.setContent(metadata.startingLocationDescription);
		this.$.author.setContent(metadata.author);
		this.$.version.setContent(metadata.version);
	},
	
	goBack: function(){
		this.owner.goBack();
	}
});
