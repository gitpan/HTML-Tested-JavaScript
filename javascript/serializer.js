function _ht_flatten(pairs, data, prefix) {
	for(var n in data) {
		var v = data[n];
		if (v instanceof Array)
			for (var i = 0; i < v.length; i++)
				_ht_flatten(pairs, v[i],
					prefix + n + "__" + (i + 1) + "__");
		else 
			pairs.push([ prefix + n, v ]);
	}
}

function ht_serializer_flatten(data) {
	var pairs = [];
	_ht_flatten(pairs, data, "");
	return pairs;
}

function ht_serializer_submit(val, url, cb) {
	var req = new XMLHttpRequest();
	if (cb)
		req.onreadystatechange = function() {
			if (req.readyState == 4)
				cb(req);
		};
	req.open("POST", url, !!cb);
	req.setRequestHeader("Content-Type"
			, "application/x-www-form-urlencoded");
	req.send(ht_serializer_flatten(val).map(function(a) {
		return a[0] + '=' + encodeURIComponent(a[1])
					.replace(/%20/g, "+");
	}).join('&'));
	return req;
}

function ht_serializer_prepare_form(form_id, ser) {
	var form = document.getElementById(form_id);
	ht_serializer_flatten(ser).forEach(function(a) {
		h = document.createElement("input");
		h.type = "hidden";
		h.name = a[0];
		h.id = a[0];
		h.value = a[1];
		h._ht_ser_generated = true;
		form.appendChild(h);
	});
}

function ht_serializer_reset_form(form_id) {
	var form = document.getElementById(form_id);
	var form_els = form.elements;
	var arr = [];
	for (var i = 0; i < form_els.length; i++)
		arr.push(form_els[i]);

	for (var i = 0; i < arr.length; i++) {
		if (!arr[i]._ht_ser_generated)
			continue;
		arr[i].parentNode.removeChild(arr[i]);
		delete form[ arr[i].name ];
	}
}

function ht_serializer_get(url) {
	var req = new XMLHttpRequest();
	req.open("GET", url, false);
	req.send(null);
	return req;
}

function ht_serializer_extract(n, str) {
	return str.replace(new RegExp("^[\\s\\S]*<script>//<!\\[CDATA\\[\\nvar "
		+ n + " = ", "m"), "")
			.replace(/;\/\/\]\]>\n<\/script>[\s\S]*$/m, "");
}

