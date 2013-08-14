/* Load this script using conditional IE comments if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'icomoon\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-cogs' : '&#x61;',
			'icon-cog' : '&#x62;',
			'icon-magnifier' : '&#x64;',
			'icon-tags' : '&#x65;',
			'icon-list' : '&#x66;',
			'icon-checkmark' : '&#x67;',
			'icon-braces' : '&#x68;',
			'icon-uniF47C' : '&#x69;',
			'icon-reload' : '&#x6a;',
			'icon-selectionadd' : '&#x6c;',
			'icon-selectionrmove' : '&#x6d;',
			'icon-uniF48A' : '&#x6e;',
			'icon-uniF48B' : '&#x6f;',
			'icon-refresh' : '&#x70;',
			'icon-resize-vertical' : '&#x71;',
			'icon-caret-up' : '&#x72;',
			'icon-caret-down' : '&#x73;',
			'icon-sign-blank' : '&#x74;',
			'icon-remove' : '&#x75;',
			'icon-remove-2' : '&#x76;',
			'icon-paragraph-left' : '&#x77;',
			'icon-stats' : '&#x78;',
			'icon-link' : '&#x79;',
			'icon-image' : '&#x7a;',
			'icon-cabinet' : '&#x31;',
			'icon-paragraph-center' : '&#x32;',
			'icon-download' : '&#x33;',
			'icon-wrench' : '&#x34;',
			'icon-move' : '&#x35;',
			'icon-multiply' : '&#x36;',
			'icon-github' : '&#x37;'
		},
		els = document.getElementsByTagName('*'),
		i, attr, html, c, el;
	for (i = 0; ; i += 1) {
		el = els[i];
		if(!el) {
			break;
		}
		attr = el.getAttribute('data-icon');
		if (attr) {
			addIcon(el, attr);
		}
		c = el.className;
		c = c.match(/icon-[^\s'"]+/);
		if (c && icons[c[0]]) {
			addIcon(el, icons[c[0]]);
		}
	}
};