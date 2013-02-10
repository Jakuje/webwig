enyo.kind({
	name: "WIGApp.GameMain.ActionRow",
	kind: enyo.HFlexBox,
	flex: 1,
	components: [
		{kind: "Item", layoutKind: "VFlexLayout", pack: "center",
		align: "center", style: "width: 100px;", components: [
			{name: "icon", kind: "Image", src: "images/you_see.png"},
			{name: "title", content: "You See"},
			{name: "numRows", content: "0"}
		]},
		{kind: "Scroller", flex: 1, style: "width: 100%;", components: [
			{kind: "VirtualRepeater", name: "items", onSetupRow: "getItem", components: [
				{kind: "Item", layoutKind: "HFlexLayout", components: [
					{name: "itemTitle", flex: 1},
				]}
			]}
		]}
	],
	getItem: function(inSender, inIndex){
		if (inIndex < 1) {
			this.$.itemTitle.setContent("Nothing here" + inIndex);
			return true;
		}
	}
});
