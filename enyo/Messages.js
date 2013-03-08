enyo.kind({
	name: "WIGApp.Dialog",
	title: "Message",
	message: "",
	media: "",
	constructor: function(message, title, media){
		this.message = message;
		this.title = title;
		this.media = media;
	},
	paintHeader: function(element){
		element.$.errorMessage.setCaption(this.title);
		element.$.errorText.setContent(this.message);
		if( this.media && this.media != "" ){
			element.$.media.setSrc(this.media);
			element.$.media.show();
		} else {
			element.$.media.hide();
		}
		
		element.$.Button1.setCaption("OK");
		
		element.$.Button2.hide();
		
		element.$.getInput.hide();
		element.$.choices.hide();
	},
	showPopup: function(element){
		this.paintHeader(element);
		
		element.$.errorMessage.openAtCenter();
	},
	hidePopup: function(element, inSender, inEvent){
		element.$.errorMessage.close();
		
	}
});
	
enyo.kind({
	kind: "WIGApp.Dialog",
	name: "WIGApp.MessageBox",
	button1: "",
	button2: "",
	callback: false,
	constructor: function(message, title, media, button1, button2, callback){
		this.inherited(arguments);
		this.button1 = button1;
		this.button2 = button2;
		this.callback = callback;
	},
	showPopup: function(element){
		this.paintHeader(element);
		
		if( this.button1 ){
			element.$.Button1.setCaption(this.button1);
		} else {
			element.$.Button1.setCaption("OK");
		}
		element.$.Button1.show();
		
		if( this.button2 ){
			element.$.Button2.setCaption(this.button2);
			element.$.Button2.show();
		} else {
			element.$.Button2.hide()
		}
		
		element.$.errorMessage.openAtCenter();
	},
	hidePopup: function(element, inSender, inEvent){
		this.inherited(arguments);
		
		if( typeof this.callback == "function" ){
			// internal usage, JS function is callback
			this.callback( element, inSender.getName() );
		} else if( this.callback == true ){
			element.$.plugin.MessageBoxResponse(inSender.getName());
		}
		
	}
});

enyo.kind({
	kind: "WIGApp.Dialog",
	name: "WIGApp.GetInput",
	type: "Text",
	choices: [],
	constructor: function(message, title, media, type, choices){
		this.inherited(arguments);
		this.type = type;
		this.choices = choices.split(";");
	},
	showPopup: function(element){
		this.paintHeader(element);
		
		if( this.type == "Text" ){
			element.$.getInput.setValue("");
			element.$.getInput.forceFocus();
			element.$.getInput.show();
		} else if( this.type == "MultipleChoice" ){
			element.$.choices.show();
			element.$.choices.render();
			element.$.Button1.hide();
		} else {
			console.error("Unknown type of getInput")
		}
		
		element.$.errorMessage.openAtCenter();
	},
	hidePopup: function(element, inSender, inEvent){
		this.inherited(arguments);
		if( this.type == "MultipleChoice" ){
			element.$.plugin.GetInputResponse( this.choices[inEvent.rowIndex] );
		} else {
			element.$.plugin.GetInputResponse( element.$.getInput.getValue() );
		}
	}
});
