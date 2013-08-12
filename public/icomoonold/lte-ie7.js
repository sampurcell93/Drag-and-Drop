/* Load this script using conditional IE comments if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'icomoon\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-cogs' : '&#xe001;',
			'icon-cog' : '&#xe002;',
			'icon-box' : '&#xe000;',
			'icon-layout' : '&#xe003;',
			'icon-layout-2' : '&#xe004;',
			'icon-layout-3' : '&#xe005;',
			'icon-layout-4' : '&#xe006;',
			'icon-layout-5' : '&#xe007;',
			'icon-layout-6' : '&#xe008;',
			'icon-layout-7' : '&#xe009;',
			'icon-layout-8' : '&#xe00a;',
			'icon-layout-9' : '&#xe00b;',
			'icon-layout-10' : '&#xe00c;',
			'icon-magnifier' : '&#xe00d;',
			'icon-layout-11' : '&#xe00e;',
			'icon-layout-12' : '&#xe00f;',
			'icon-layout-13' : '&#xe010;',
			'icon-layout-14' : '&#xe011;',
			'icon-tags' : '&#xe012;',
			'icon-list' : '&#xe013;',
			'icon-multiply' : '&#xd7;',
			'icon-braces' : '&#xf0b4;',
			'icon-uniF47C' : '&#xf47c;',
			'icon-refresh' : '&#xf078;',
			'icon-trash' : '&#xf0ce;',
			'icon-trashempty' : '&#xf0cf;',
			'icon-trashfull' : '&#xf0d0;',
			'icon-selectionadd' : '&#xf1b2;',
			'icon-selectionrmove' : '&#xf1b3;',
			'icon-uniF48A' : '&#xf48a;',
			'icon-uniF48B' : '&#xf48b;',
			'icon-uniF489' : '&#xf489;',
			'icon-uniF488' : '&#xf488;',
			'icon-reload' : '&#xe014;',
			'icon-fullscreen' : '&#xf0b2;',
			'icon-resize-vertical' : '&#xf07d;',
			'icon-caret-up' : '&#xf0d8;',
			'icon-caret-down' : '&#xf0d7;',
			'icon-sign-blank' : '&#xf0c8;',
			'icon-remove' : '&#xe015;',
			'icon-remove-2' : '&#xe016;',
			'icon-paragraph-left' : '&#xe018;',
			'icon-stats' : '&#xe017;',
			'icon-link' : '&#xe019;',
			'icon-image' : '&#xe01a;',
			'icon-cabinet' : '&#xe01b;'
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