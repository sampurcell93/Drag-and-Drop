/* Load this script using conditional IE comments if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'icomoon\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-pushpin' : '&#x61;',
			'icon-tag' : '&#x62;',
			'icon-folder' : '&#x63;',
			'icon-stack' : '&#x64;',
			'icon-cog' : '&#x65;',
			'icon-move' : '&#x66;',
			'icon-close' : '&#x67;',
			'icon-layout' : '&#x68;',
			'icon-grid' : '&#x69;',
			'icon-list' : '&#x6a;',
			'icon-list-2' : '&#x6b;',
			'icon-list-3' : '&#x6c;',
			'icon-refresh' : '&#x6d;',
			'icon-repeat' : '&#x6e;',
			'icon-cancel' : '&#x6f;',
			'icon-arrow-down' : '&#x70;',
			'icon-arrow-up' : '&#x71;',
			'icon-arrow-left' : '&#x72;',
			'icon-arrow-right' : '&#x73;',
			'icon-resize-vertical' : '&#x74;'
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