// The Help scene displays at least one method of support (developer website, phone number, email) that works. It can also contain links to application-related help, frequently asked questions, etc.

enyo.kind({
	name: "WIGApp.Help",
	kind: "Scroller",
	components: [
		{kind: "Item", content: "WebWIG app by Jakuje"},
		{kind: "RowGroup", caption: "Help", components: [
			{kind: "HFlexBox", onclick: "showWeb", components: [
				{kind: "Image", src: "images/browser.png", style: "width:50%;margin: -7px 0;"},
				{content: "Support"},
			]},
			{kind: "HFlexBox", onclick: "showForums", components: [
				{kind: "Image", src: "images/browser.png", style: "width:50%;margin: -7px 0;"},
				{content: "Discussion forums"},
			]}
		]},
		{kind: "RowGroup", caption: "Contact", components: [
			{kind: "HFlexBox", onclick: "showEmail", components: [
				{kind: "Image", src: "images/email.png", style: "width:50%;margin: -7px 0;"},
				{content: "Email contact"},
			]}
		]},
		{kind: "Item", content: "© Copyright 2013 Jakuje"},
		{
            name : "browser",
            kind : "PalmService",
            service : "palm://com.palm.applicationManager",
            method : "open",
         }
	],
	showWeb: function(){
		this.$.browser.call({"target": "http://jakuje.dta3.com/webwig.phtml"});
	},
	showForums: function(){
		this.$.browser.call({"target": "http://forums.webosnation.com/webos-development/315852-wherigo-webos.html"});
	},
	showEmail: function(){
		this.$.browser.call({"target": "mailto: jakuje@gmail.com"});
	},
});
