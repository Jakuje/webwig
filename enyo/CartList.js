enyo.kind({
	name: "WIGApp.CartList",
	kind: "VFlexBox",
	events: { 
		onPlay: "",
		onInfo: "",
	},
	components: [
		{kind: "PageHeader", components: [
			{kind: "IconButton", icon: "images/menu-icon-back.png", onclick: "goBack"},
			{layoutKind: "VFlexLayout", flex: 1, align: "center", components: [
				{name: "title", content: "Cartridges"},
				{name: "subtitle", content: "&nbsp;", className: "enyo-item-secondary", allowHtml: true},
				]},
			{kind: "IconButton", icon: "images/menu-icon-sync.png", onclick: "refreshClicked"}
		]},
		{kind: "Scroller", flex: 1, horizontal: false, autoHorizontal: false,
			components: [
			{name: "list", kind: "VirtualRepeater",
				onSetupRow: "listGetItem", onclick: "playCartridge",
				components: [
					{kind: "Item", layoutKind: "VFlexLayout", tapHighlight: true, components: [
						{name: "cTitle", kind: "Divider", allowHtml: true},
						{layoutKind: "HFlexLayout", components: [
							{layoutKind: "VFlexLayout", flex: 1, components: [
								{name: "type"},
								{name: "author"},
								]},
							{kind: "IconButton", icon: "images/menu-icon-info.png", onclick: "showDetails"}
						]}
					]}
				]
			}
		]},
		{kind: "Item", name: "empty", layoutKind: "HFlexLayout", components: [
			{name: "nothingText", content: "No cartridges found in working directory",
			flex: 1, style: "font-style:italic;text-align:center; color:#999999;"}
		]},
    ],
   	metadata: [],
   	type: "All",
   	state: "All",
   	anywhere: false,

	create: function() {
		this.inherited(arguments);
	},
	
	setup: function(type, state, anywhere){
		this.type = type;
		this.state = state;
		this.anywhere = anywhere;
		this.updateTitle();
		this.getCartridges(0);
	},
	
	updateTitle: function(){
		if( this.anywhere ){
			this.$.title.setContent("Play anywhere");
		} else {
			this.$.title.setContent("Cartridges");
		}
		subtitle = "";
		if( this.type != "All" ){
			subtitle += "Type: " + this.type;
		}
		if( this.state != "All" ){
			subtitle += ( subtitle.length != 0 ? ", " : "") + "State: " + this.state;
		}
		this.$.subtitle.setContent( (subtitle.length != 0 ? subtitle : "&nbsp;") );
	},
	
	refreshClicked: function(){
		this.getCartridges(1);
	},
	
	getCartridges: function( refresh ) {
		//this.$.directory.setContent("Current Directory: " + this.directory);
		this.owner.$.plugin.getCartridges(refresh, enyo.bind(this, this.updateFileList));
		//this.$.parent.setDisabled(this.directory === "/");
	},
	
	updateFileList: function(metadata) {
		data = [];
		for(var i in metadata){
			if( (this.type == 'All' || metadata[i].type == this.type)
			&& ( this.anywhere == (metadata[i].latitude == 360 && metadata[i].longitude == 360) )
			/* TODO state */ ){
				data.push(metadata[i]);
			}
		}
		this.metadata = data;
		console.error("***** WIG Enyo: updateFileList");
		if( this.metadata.length == 0 ){
			this.$.scroller.hide();
			this.$.nothingText.setContent("No cartridges found in working directory");
			this.$.empty.show();
		} else {
			this.$.scroller.show();
			this.$.empty.hide();
			this.$.list.render();
			this.$.scroller.setScrollTop(0);
		}
	},

	listGetItem: function(inSender, inIndex) {
		if (inIndex < this.metadata.length) {
			if (this.$.list) {
				var item = this.metadata[inIndex];
				this.$.cTitle.setCaption( item.name + (item.saved ? " [S]" : ""));
				this.$.type.setContent( item.type );
				if( item.author ){
					this.$.author.setContent(" by " + item.author);
				} else {
					this.$.author.setContent("");
				}
				if( this.metadata[inIndex].icon ){
					this.$.cTitle.setIcon(DATA_DIR + "." + item.guid + "/" + item.icon);
				} else {
					this.$.cTitle.setIcon("");
				}
			}
			return true;
		}
		return false;
	},
	showDetails: function(inSender, inEvent){
		if (inEvent.rowIndex < this.metadata.length) {
			var c = this.metadata[inEvent.rowIndex];
			this.doInfo(c);
		}
		inEvent.stopPropagation();
	},
	playCartridge: function(inSender, inEvent){
		if (inEvent.rowIndex < this.metadata.length) {
			var c = this.metadata[inEvent.rowIndex];
			this.doPlay(c);
		}
	},
	
	goBack: function(inSender, inEvent){
		this.owner.goBack(inSender, inEvent);
	},

});
