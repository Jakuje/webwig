enyo.kind({
	name: "WIGApp.CartList",
	kind: "VFlexBox",
	events: { 
		onPlay: "",
		onInfo: "",
	},
	components: [
		{kind: "PageHeader", components: [
			{kind: "Spacer"},
			{content: "Cartridges"},
			{kind: "Spacer"},
			{kind: "IconButton", icon: "images/menu-icon-sync.png", onclick: "refreshClicked"}
		]},
		{kind: "Scroller", flex: 1, components: [
			{name: "list", kind: "VirtualRepeater",
				onSetupRow: "listGetItem", onclick: "playCartridge",
				components: [
					{kind: "Item", layoutKind: "VFlexLayout", components: [
						{name: "title", kind: "Divider", allowHtml: true},
						{layoutKind: "HFlexLayout", components: [
							{name: "description"},
							{kind: "Spacer"},
							{kind: "IconButton", icon: "images/menu-icon-info.png", onclick: "showDetails"}
						]}
					]}
				]
			}
		]},
      {kind: "Button", caption: "Dialog", onclick: "openError"},
    ],
   	metadata: [],


   	openError: function() {
		//this.$.errorMessage.openAtCenter();
		this.owner.popupMessage("Zprava chybova");
	},

	create: function() {
		this.inherited(arguments);
		this.getCartridges(0);
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
		console.error("***** WIG Enyo: updateFileList");
		this.metadata = metadata;
		this.$.list.render();
		this.$.scroller.setScrollTop(0);
	},

	listGetItem: function(inSender, inIndex) {
		if (inIndex < this.metadata.length) {
			if (this.$.list) {
				// important to escape this, as filenames are user-generated content
				this.$.title.setCaption(this.metadata[inIndex].name);
				this.$.description.setContent(this.metadata[inIndex].type + " by " + this.metadata[inIndex].author);
				if( this.metadata[inIndex].iconID != -1 ){
					this.$.title.setIcon(DATA_DIR + this.metadata[inIndex].guid + '_icon.png');
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
	}

});
