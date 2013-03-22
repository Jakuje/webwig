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
					{kind: "Item", layoutKind: "VFlexLayout", tapHighlight: true, components: [
						{name: "title", kind: "Divider", allowHtml: true},
						{layoutKind: "HFlexLayout", components: [
							{layoutKind: "VFlexLayout", components: [
								{name: "type"},
								{name: "author"},
								]},
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
		
		this.owner.popupMessage( new WIGApp.Dialog("1 JAK HRAT:<BR><BR>V nabidce Tasks (Ukoly) najdete konkretni ukoly. Pro jejich splneni staci priblizit se k hledanemu objektu. Na poradi techto objektu pritom nezalezi.<BR><BR>Vzdy vyckejte na potvrzeni nalezu. Nekdy se muze stat, ze budete muset hledat spravne misto, aby byl nalez zaznamenan a potvrzen.<BR><BR>Pozorne ctete pruvodni texty. Reknou vam, jak postupovat dal. Kazdy dialog hned potvrdte tlacitkem.<BR><BR>Kdybyste si nevedeli rady, prozkoumejte polozky v jednotlivych nabidkach.<BR><BR>Hra se automaticky po splneni kazdeho ukolu uklada.", "Message") );
		this.owner.popupMessage( new WIGApp.Dialog("2 JAK HRAT:<BR><BR>V nabidce Tasks (Ukoly) najdete konkretni ukoly. Pro jejich splneni staci priblizit se k hledanemu objektu. Na poradi techto objektu pritom nezalezi.<BR><BR>Vzdy vyckejte na potvrzeni nalezu. Nekdy se muze stat, ze budete muset hledat spravne misto, aby byl nalez zaznamenan a potvrzen.<BR><BR>Pozorne ctete pruvodni texty. Reknou vam, jak postupovat dal. Kazdy dialog hned potvrdte tlacitkem.<BR><BR>Kdybyste si nevedeli rady, prozkoumejte polozky v jednotlivych nabidkach.<BR><BR>Hra se automaticky po splneni kazdeho ukolu uklada.", "Message") );
		this.owner.popupMessage( new WIGApp.Dialog("3 JAK HRAT:<BR><BR>V nabidce Tasks (Ukoly) najdete konkretni ukoly. Pro jejich splneni staci priblizit se k hledanemu objektu. Na poradi techto objektu pritom nezalezi.<BR><BR>Vzdy vyckejte na potvrzeni nalezu. Nekdy se muze stat, ze budete muset hledat spravne misto, aby byl nalez zaznamenan a potvrzen.<BR><BR>Pozorne ctete pruvodni texty. Reknou vam, jak postupovat dal. Kazdy dialog hned potvrdte tlacitkem.<BR><BR>Kdybyste si nevedeli rady, prozkoumejte polozky v jednotlivych nabidkach.<BR><BR>Hra se automaticky po splneni kazdeho ukolu uklada.", "Message") );
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
				var item = this.metadata[inIndex];
				this.$.title.setCaption( item.name );
				this.$.type.setContent( item.type );
				if( item.author ){
					this.$.author.setContent(" by " + item.author);
				} else {
					this.$.author.setContent("");
				}
				if( this.metadata[inIndex].icon ){
					this.$.title.setIcon(item.icon);
				} else {
					this.$.title.setIcon("");
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
