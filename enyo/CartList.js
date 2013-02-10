enyo.kind({
	name: "WIGApp.CartList",
	kind: "VFlexBox",
	events: { 
		onSelect: ""
	},
	components: [
	  {kind: "PageHeader", components: [
		{kind: "Spacer"},
		{kind: enyo.VFlexBox, content: "Cartridges"},
		{kind: "Spacer"},
		{kind: "IconButton", icon: "images/menu-icon-refresh.png", onclick: "refreshClicked"}
		]},
      {kind: "Scroller", flex: 1, components: [
			{name: "list", kind: "VirtualRepeater", onSetupRow: "listGetItem"/*, onclick: "changeDirectory"*/,
				components: [
					{kind: "Item", layoutKind: "VFlexLayout", components: [
						{name: "title", kind: "Divider", allowHtml: true},
						{layoutKind: "HFlexLayout", components: [
							{name: "description"},
							{kind: "Spacer"},
							{kind: "IconButton", icon: "images/more-menu-icon.png", onclick: "showDetails"}
						]}
					]}
				]
			}
		]},
      {kind: "Button", caption: "Dialog", onclick: "openError"},
	  {
		   kind: "ModalDialog",
		   name: "errorMessage",
		   caption: "Error",
		   components: [
				{
					content: "Chyba toho a toho.",
					className: "enyo-text-error warning-icon"
				},
				{
					kind: "Button",
					caption: "OK",
					onclick: "closeError",
				}
		   ]
		}
    ],
   	metadata: [],


   	openError: function() {
		this.$.errorMessage.openAtCenter();
	},
	closeError: function(inSender, inEvent) {
		this.$.errorMessage.close();
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
		var c = this.metadata[inEvent.rowIndex];
		this.doSelect(c);
	}

});
