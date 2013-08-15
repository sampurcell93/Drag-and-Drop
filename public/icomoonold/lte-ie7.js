/* Load this script using conditional IE comments if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'icomoon\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-cogs' : '&#xe000;',
			'icon-cog' : '&#xe001;',
			'icon-magnifier' : '&#xe002;',
			'icon-tags' : '&#xe003;',
			'icon-list' : '&#xe004;',
			'icon-checkmark' : '&#xe005;',
			'icon-braces' : '&#xe006;',
			'icon-uniF47C' : '&#xe007;',
			'icon-reload' : '&#xe008;',
			'icon-selectionadd' : '&#xe009;',
			'icon-selectionrmove' : '&#xe00a;',
			'icon-uniF48A' : '&#xe00b;',
			'icon-uniF48B' : '&#xe00c;',
			'icon-refresh' : '&#xe00d;',
			'icon-resize-vertical' : '&#xe00e;',
			'icon-caret-up' : '&#xe00f;',
			'icon-caret-down' : '&#xe010;',
			'icon-sign-blank' : '&#xe011;',
			'icon-remove' : '&#xe012;',
			'icon-remove-2' : '&#xe013;',
			'icon-paragraph-left' : '&#xe014;',
			'icon-stats' : '&#xe015;',
			'icon-link' : '&#xe016;',
			'icon-image' : '&#xe017;',
			'icon-cabinet' : '&#xe018;',
			'icon-paragraph-center' : '&#xe019;',
			'icon-download' : '&#xe01a;',
			'icon-wrench' : '&#xe01b;',
			'icon-move' : '&#xe01c;',
			'icon-multiply' : '&#xe01d;',
			'icon-github' : '&#xe01e;'
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