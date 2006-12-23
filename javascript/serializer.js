function ht_encode_form_data(pairs, data, prefix) {
	var re = /%20/g;
	for(var n in data) {
		var v = data[n];
		var ne = encodeURIComponent(n).replace(re, "+");
		if (v instanceof Array)
			for (var i = 0; i < v.length; i++)
				ht_encode_form_data(pairs, v[i],
					prefix + ne + "__" + (i + 1) + "__");
		else {
			var ve = encodeURIComponent(v).replace(re, "+");
			var p = prefix + ne + '=' + ve;
			pairs.push(p);
		}
	}
}

function ht_serializer_submit(val, url, cb) {
	var req = new XMLHttpRequest();
	if (cb)
		req.onreadystatechange = function() {
			if (req.readyState == 4)
				cb(req);
		};
	var pairs = [];
	req.open("POST", url, !!cb);
	req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	ht_encode_form_data(pairs, val, "");
	req.send(pairs.join('&'));
	return req;
}

