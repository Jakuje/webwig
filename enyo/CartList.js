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
		{kind: "Scroller", flex: 1, horizontal: false, autoHorizontal: false,
			components: [
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
		{name: "error", showing: "false", flex: 1, textAlign: "center"},
      {kind: "Button", caption: "Dialog", onclick: "openError"},
    ],
   	metadata: [],


   	openError: function() {
		this.owner.popupMessage( new WIGApp.MessageBox("Zprava chybova", "Message", "images/tasks.png", "Dobre", "Spatne", true) );
		//this.owner.popupMessage( new WIGApp.Dialog("Je prave zobrazena prvni zprava a tato by mela zustat v zasobniku", "Error", "images/tasks.png") );
		this.owner.popupMessage( new WIGApp.Dialog("JAK HRAT:<BR><BR>V nabidce Tasks (Ukoly) najdete konkretni ukoly. Pro jejich splneni staci priblizit se k hledanemu objektu. Na poradi techto objektu pritom nezalezi.<BR><BR>Vzdy vyckejte na potvrzeni nalezu. Nekdy se muze stat, ze budete muset hledat spravne misto, aby byl nalez zaznamenan a potvrzen.<BR><BR>Pozorne ctete pruvodni texty. Reknou vam, jak postupovat dal. Kazdy dialog hned potvrdte tlacitkem.<BR><BR>Kdybyste si nevedeli rady, prozkoumejte polozky v jednotlivych nabidkach.<BR><BR>Hra se automaticky po splneni kazdeho ukolu uklada.", "Message") );
		this.owner.popupMessage( new WIGApp.GetInput("Vyberte:", "Select", "images/you_see.png", "MultipleChoice", ";one;two;three;saf;fasfvsav;vas;vfavfad;"));
		this.owner.popupMessage( new WIGApp.GetInput("Zadejte text:", "Input", "images/inventory.png", "Text", ""));
		
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
		if( metadata.length == 0 ){
			this.$.scroller.hide();
			this.$.error.setContent("No cartridges found in working directory");
		} else {
			this.$.scroller.show();
			this.$.error.hide();
			this.metadata = metadata;
			this.$.list.render();
			this.$.scroller.setScrollTop(0);
		}
	},

	listGetItem: function(inSender, inIndex) {
		if (inIndex < this.metadata.length) {
			if (this.$.list) {
				// important to escape this, as filenames are user-generated content
				this.$.title.setCaption(this.metadata[inIndex].name);
				this.$.description.setContent(this.metadata[inIndex].type + " by " + this.metadata[inIndex].author);
				if( this.metadata[inIndex].icon ){
					this.$.title.setIcon(this.metadata[inIndex].icon);
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
