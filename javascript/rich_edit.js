function _htre_win(id) { return document.getElementById(id).contentWindow; }
function htre_document(id) { return _htre_win(id).document; }

function _htre_parse_id(d) {
	var arr = d.id.match(/^(.+)_(\w+)$/);
	return [ arr[1], arr[2] ];
}

var _htre_state_tags = { FONT: [ "fontsize", function(n) { return n.size; } ]
	, OL: [ "insertorderedlist", function(n) { return true; } ]
	, A: [ "link", function(a) { return a.href; } ]
	, UL: [ "insertunorderedlist", function(n) { return true; } ] };

var _htre_state_styles = { fontname: "fontFamily", forecolor: "color"
		, hilitecolor: "backgroundColor", bold: "fontWeight"
		, underline: "textDecoration", italic: "fontStyle"
		, textalign: "textAlign" };

function htre_get_selection_state(id) {
	var w = _htre_win(id);
	var sel = w.getSelection();
	if (!sel)
		return;

	var res = { selection: sel };
	for (var an = sel.anchorNode; an; an = an.parentNode) {
		if (!an.tagName)
			continue;

		var st = _htre_state_tags[an.tagName];
		if (st && !(st[0] in res))
			res[ st[0] ] = st[1](an);

		for (var i in _htre_state_styles)
			if (!res[i])
				res[i] = an.style[ _htre_state_styles[i] ];
	}
	res[ "justify" + res.textalign ] = true;
	return res;
}

function htre_get_selection(id) {
	return _htre_win(id).getSelection();
}

function htre_focus(id) {
	setTimeout(function() { _htre_win(id).focus(); }, 0);
}

function htre_exec_command(id, cmd, arg) {
	htre_document(id).execCommand(cmd, false, arg);
	htre_focus(id);
}

function _htre_exec_cmd_with_tag(d, arg) {
	var [ eid, cmd ] = _htre_parse_id(d);
	htre_exec_command(eid, cmd, arg);
}

function _htre_but_command(e) { _htre_exec_cmd_with_tag(e.currentTarget); }

function _htre_sel_command(e) {
	var d = e.currentTarget;
	if (d.selectedIndex > 0)
		_htre_exec_cmd_with_tag(d, d.options[d.selectedIndex].value);
	else
		htre_focus(_htre_parse_id(d)[0]);
}

var _htre_modifiers = [ [ "bold", "click", _htre_but_command ]
	, [ "italic", "click", _htre_but_command ]
	, [ "underline", "click", _htre_but_command ]
	, [ "justifyleft", "click", _htre_but_command ]
	, [ "justifyright", "click", _htre_but_command ]
	, [ "justifycenter", "click", _htre_but_command ]
	, [ "insertorderedlist", "click", _htre_but_command ]
	, [ "insertunorderedlist", "click", _htre_but_command ]
	, [ "outdent", "click", _htre_but_command ]
	, [ "indent", "click", _htre_but_command ]
	, [ "undo", "click", _htre_but_command ]
	, [ "redo", "click", _htre_but_command ]
	, [ "fontname", "change", _htre_sel_command ]
	, [ "fontsize", "change", _htre_sel_command ] ];

function htre_init(id) {
	/* Do it only once - no way to test it ... */
	if (htre_document(id).designMode == "on")
		return;

	htre_document(id).designMode = "on";
	for each (var mod in _htre_modifiers) {
		var bo = document.getElementById(id + "_" + mod[0]);
		if (!bo)
			continue;

		/* For some reason, closure doesn't work here ... */
		bo.addEventListener(mod[1], mod[2], false);
	}
}

function htre_register_on_load(id) {
	window.addEventListener("load", function() { htre_init(id) }, false);
}

function htre_get_inner_xml(node) {
	var xml = (new XMLSerializer()).serializeToString(node);
	var b = new RegExp("^<" + node.nodeName + "[^>]*>");
	var e = new RegExp("</" + node.nodeName + ">$");
	return xml.replace(b, "").replace(e, "").replace(/ _moz_dirty=""/g, "");
}

function htre_get_value(id) {
	/* innerHTML doesn't return valid XML, so do it hard way... */
	return htre_get_inner_xml(htre_document(id).body);
}

function htre_set_value(id, val) {
	htre_document(id).body.innerHTML = val;
}

function htre_add_onchange_listener(id, func) {
	htre_document(id).addEventListener("blur", func, false);
}

var _htre_tag_whitelist = { SPAN: 1, BR: 1, P: 1, "#text": 1, HTRE: 1
	, FONT: 1, DIV: 1, OL: 1, LI: 1, UL: 1, A: 1 };
var _htre_attr_whitelist = { style: 1, size: 1, href: 1 };
function _htre_escape_filter(doc) {
	for each (var d in doc.childNodes) {
		if (!d || !d.nodeName)
			continue;

		if (!_htre_tag_whitelist[d.nodeName]) {
			d.parentNode.removeChild(d);
			continue;
		}

		for each (var a in d.attributes) {
			if (!a || !a.nodeName)
				continue;
			if (!_htre_attr_whitelist[a.nodeName])
				d.removeAttribute(a.name);
		}

		_htre_escape_filter(d);
	}
}

function htre_escape(str) {
	str = "<HTRE>" + str + "</HTRE>"; 
	var doc = (new DOMParser()).parseFromString(str, "application/xml");
	_htre_escape_filter(doc);
	return htre_get_inner_xml(doc.getElementsByTagName("HTRE")[0]);
}

function htre_do_tick(doc, name, cb, msecs) {
	if (doc._htre_tick_active)
		return;

	doc._htre_tick_active = true;
	setTimeout(function() {
		var state = htre_get_selection_state(name);
		if (state)
			cb(name, state);
		doc._htre_tick_active = false;
	}, msecs);
}

function htre_listen_for_state_changes(name, cb, msecs) {
	var doc = htre_document(name);
	var f = function(e) { htre_do_tick(e.currentTarget, name, cb, msecs); };
	doc.addEventListener("keypress", f, true);
	doc.addEventListener("blur", f, true);
	doc.addEventListener("focus", f, true);
}
