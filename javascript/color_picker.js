/* r, g, b are between 0-255. h is in [0-360]. v,s in [0-100] */
function htcp_rgb_to_hsv(r, g, b) {
	var h, s, v;
	var min, max, delta;

	r /= 255;
	g /= 255;
	b /= 255;

	min = Math.min(r, g, b);
	max = Math.max(r, g, b);
	v = max;

	delta = max - min;
	if (max != 0)
		s = delta / max;
	else 
		return [ 0, 0, 0 ];

	if( r == max )
		h = (g - b) / delta;
	else if(g == max)
		h = 2 + (b - r) / delta;
	else
		h = 4 + (r - g) / delta;

	h *= 60;
	if(h < 0)
		h += 360;
	else if (isNaN(h))
		h = 360;

	return [ Math.round(h), Math.round(s * 100), Math.round(v * 100) ];
}

function htcp_client_x(e) { return e.clientX + window.pageXOffset; }
function htcp_client_y(e) { return e.clientY + window.pageYOffset; }

function htcp_save_x_dimensions(el, e, ctx) {
	ctx.down_x = htcp_client_x(e);
	ctx.el_x = parseFloat(el.style.left);
}

function htcp_save_y_dimensions(el, e, ctx) {
	ctx.down_y = htcp_client_y(e);
	ctx.el_y = parseFloat(el.style.top);
}

function htcp_move_by_x(el, e, ctx) {
	var pos = htcp_client_x(e) - ctx.down_x + ctx.el_x;
	var max = el.parentNode.offsetWidth - parseFloat(el.style.width);
	if (pos > max)
		pos = max;
	else if (pos < 0)
		pos = 0;
	el.style.left = pos + "px";
}

function htcp_move_by_y(el, e, ctx) {
	var pos = htcp_client_y(e) - ctx.down_y + ctx.el_y;
	var max = el.parentNode.offsetHeight - parseFloat(el.style.height);
	if (pos > max)
		pos = max;
	else if (pos < 0)
		pos = 0;
	el.style.top = pos + "px";
}

function htcp_listen_for_mouse_events(el, mdown, mmove, mup) {
	var myup = function(e) {
		document.removeEventListener("mousemove", mmove, true);
		document.removeEventListener("mouseup", myup, true);
		mup(e);
	}
	var mydown = function(e) {
		document.addEventListener("mousemove", mmove, true);
		document.addEventListener("mouseup", myup, true);
		mdown(e);
	}
	el.addEventListener("mousedown", mydown, false);
	return mydown;
}

function htcp_init(name, hook) {
	window.addEventListener("load", function(e) {
		_htcp_init(name, hook); }, false);
}

function _htcp_cond_set(id, v) {
	var eb = document.getElementById(id);
	if (eb)
		eb.value = v;
}

function _htcp_set_rgb_indicators(name, r, g, b) {
	_htcp_cond_set(name + "_rgb_r", r);
	_htcp_cond_set(name + "_rgb_g", g);
	_htcp_cond_set(name + "_rgb_b", b);
	_htcp_cond_set(name + '_rgb_hex'
		, htcp_hex(r) + htcp_hex(g) + htcp_hex(b));
	var cc = document.getElementById(name + "_current_color");
	if (cc)
		cc.style.backgroundColor = "rgb(" + r + "," + g + "," + b + ")";
	window["__htcp_" + name + "_rgb"] = [ r, g, b ];
}

function _htcp_calculate_hue_rgb(name) {
	var hup = document.getElementById(name + "_hue_pointer");
	var h_y_raw = parseFloat(hup.style.top) * 100/186;
	var c = parseInt(h_y_raw * 255/100);
	var n = 256/6, j = ((256/n) * (c % n));

	var hue_r = parseInt(c<n?255:c<n*2?255-j:c<n*4?0:c<n*5?j:255);
	var hue_g = parseInt(c<n*2?0:c<n*3?j:c<n*5?255:255-j);
	var hue_b = parseInt(c<n?j:c<n*3?255:c<n*4?255-j:0);
	document.getElementById(name + "_color").style.backgroundColor
			= "rgb(" + hue_r + "," + hue_g + "," + hue_b + ")";
	return [ hue_r, hue_g, hue_b ];
}

function _htcp_set_color_from_indicators(name) {
	var ptr = document.getElementById(name + "_color_pointer");
	var ptr_x = parseFloat(ptr.style.left) * 100/181;
	var ptr_y = parseFloat(ptr.style.top) * 100/181;
	var ptr_x_col = parseInt(ptr_x * 255/100);
	var ptr_y_col = parseInt(ptr_y * 255/100);

	var [ hue_r, hue_g, hue_b ] = _htcp_calculate_hue_rgb(name);

	var r = Math.round((1-(1-(hue_r/255))*(ptr_x_col/255))*(255-ptr_y_col));
	var g = Math.round((1-(1-(hue_g/255))*(ptr_x_col/255))*(255-ptr_y_col));
	var b = Math.round((1-(1-(hue_b/255))*(ptr_x_col/255))*(255-ptr_y_col));
	_htcp_set_rgb_indicators(name, r, g, b);
}

function htcp_set_indicators_from_rgb(name, r, g, b) {
	var [ h, s, v ] = htcp_rgb_to_hsv(r, g, b);
	document.getElementById(name + "_hue_pointer").style.top
		= Math.round(186 - (h / 360) * 186) + "px";
	var ptrs = document.getElementById(name + "_color_pointer").style;
	ptrs.left = Math.round((s / 100) * 181) + "px";
	ptrs.top = Math.round(((100 - v) / 100) * 181) + "px";
	_htcp_calculate_hue_rgb(name);
	_htcp_set_rgb_indicators(name, r, g, b);
	_htcp_set_prev_color(name);
}

function htcp_hex(c) {
	c = c.toString(16);
	return c.length < 2 ? "0" + c : c;
}

function htcp_int_to_rgb(i) {
	var r = (i & (255 << 16)) >> 16;
	var g = (i & (255 << 8)) >> 8;
	var b = (i & 255);
	return [ r, g, b ];
}

function htcp_current_color(name) { return window["__htcp_" + name + "_rgb"]; }

function _htcp_set_prev_color(name) {
	var prev = document.getElementById(name + "_prev_color");
	var cur = document.getElementById(name + "_current_color");
	if (prev && cur)
		prev.style.backgroundColor = cur.style.backgroundColor;

	var hook = window["__htcp_" + name + "_hook"];
	if (!hook)
		return;
	var arr = htcp_current_color(name);
	hook(name, arr[0], arr[1], arr[2]);
}

function _htcp_on_rgb_enter(e) {
	var id = e.currentTarget.id;
	var r = parseInt(document.getElementById(id.replace(/\w$/, "r")).value);
	var g = parseInt(document.getElementById(id.replace(/\w$/, "g")).value);
	var b = parseInt(document.getElementById(id.replace(/\w$/, "b")).value);
	htcp_set_indicators_from_rgb(id.replace(/_rgb_\w$/, ""), r, g, b);
}

function _htcp_on_hex_enter(e) {
	var inp = e.currentTarget;
	var [ r, g, b ] = htcp_int_to_rgb(parseInt("0x" + inp.value));
	_htcp_set_rgb_indicators(name, r, g, b);
	htcp_set_indicators_from_rgb(inp.id.replace(/_rgb_hex$/, ""), r, g, b);
}

function _htcp_add_rgb_hook(name, sfx, hook) {
	var eb = document.getElementById(name + "_rgb_" + sfx);
	if (!eb)
		return;
	eb.addEventListener("keydown", function(e) {
		if (e.keyCode == 13)
			hook(e);
	}, true);
	eb.addEventListener("change", hook, true);
}

function _htcp_set_style(ptr, cs, what) {
	ptr.style[what] = parseFloat(cs[what]) ? cs[what] : "0px";
}

function _htcp_init_pointer(ptr) {
	var cs = window.getComputedStyle(ptr, null);
	_htcp_set_style(ptr, cs, "width");
	_htcp_set_style(ptr, cs, "height");
	_htcp_set_style(ptr, cs, "top");
	_htcp_set_style(ptr, cs, "left");
}

function _htcp_init(name, hook) {
	var ptr = document.getElementById(name + "_color_pointer");
	_htcp_init_pointer(ptr);
	var pctx = {};
	htcp_listen_for_mouse_events(ptr, function(e) {
		htcp_save_x_dimensions(ptr, e, pctx);
		htcp_save_y_dimensions(ptr, e, pctx);
	}, function(e) {
		htcp_move_by_x(ptr, e, pctx);
		htcp_move_by_y(ptr, e, pctx);
		_htcp_set_color_from_indicators(name);
	}, function(e) { _htcp_set_prev_color(name); });

	var hup = document.getElementById(name + "_hue_pointer");
	_htcp_init_pointer(hup);
	var hctx = {};
	htcp_listen_for_mouse_events(hup, function(e) {
		htcp_save_y_dimensions(hup, e, hctx);
	}, function(e) {
		htcp_move_by_y(hup, e, hctx);
		_htcp_set_color_from_indicators(name);
	}, function(e) { _htcp_set_prev_color(name); });

	for each (var a in [ "r", "g", "b" ])
		_htcp_add_rgb_hook(name, a, _htcp_on_rgb_enter);

	_htcp_add_rgb_hook(name, "hex", _htcp_on_hex_enter);

	_htcp_set_color_from_indicators(name);
	_htcp_set_prev_color(name);
	window["__htcp_" + name + "_hook"] = hook;
}
