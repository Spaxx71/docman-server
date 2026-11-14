(function () {
	function ready(fn) {
		if (document.readyState === "loading") {
			document.addEventListener("DOMContentLoaded", fn);
		} else {
			fn();
		}
	}

	function show(id) {
		var dialog = document.getElementById(id);
		if (dialog) {
			dialog.hidden = false;
		}
	}

	function hide(id) {
		var dialog = document.getElementById(id);
		if (dialog) {
			dialog.hidden = true;
		}
	}

	function cell(row, key) {
		return row.querySelector('td[data-k="' + key + '"]');
	}

	function paint(row, seen, flagged, done) {
		row.setAttribute("data-seen", seen);
		row.setAttribute("data-flagged", flagged);
		row.setAttribute("data-erledigt", done);
		var stripe = row.className.indexOf("odd") >= 0 ? "odd" : "even";
		var other = row.getAttribute("data-year") === "false" ? " other-year" : "";
		row.className = stripe + (seen === "true" ? "" : " unread") + (flagged === "true" ? " flagged" : "") + other;
		var erledigt = cell(row, "erledigt");
		var unread = cell(row, "unread");
		var mark = cell(row, "flagged");
		erledigt.setAttribute("data-v", done === "true" ? "1" : "0");
		unread.setAttribute("data-v", seen === "true" ? "0" : "1");
		mark.setAttribute("data-v", flagged === "true" ? "1" : "0");
		erledigt.querySelector("a").innerHTML = done === "true" ? '<span class="done-mark">✓</span>' : "–";
		unread.querySelector("a").textContent = seen === "true" ? "gelesen" : "ungelesen";
		mark.querySelector("a").textContent = flagged === "true" ? "markiert" : "–";
	}

	ready(function () {
		var table = document.getElementById("mail-list");
		if (!table) {
			return;
		}
		var stateRow = null;
		var stateFlag = "";
		var stateNext = "";
		var linkEmail = "";
		var sortKey = "number";
		var sortDir = "desc";

		function question(flag, row) {
			if (flag === "seen") {
				return row.getAttribute("data-seen") === "true"
					? "Die Nachricht ist gelesen. Auf ungelesen setzen?"
					: "Die Nachricht ist ungelesen. Auf gelesen setzen?";
			}
			if (flag === "flagged") {
				return row.getAttribute("data-flagged") === "true"
					? "Die Markierung entfernen?"
					: "Die Nachricht markieren?";
			}
			return row.getAttribute("data-erledigt") === "true"
				? "Erledigt zurücknehmen?"
				: "Die Nachricht als erledigt markieren?";
		}

		function nextValue(flag, row) {
			if (flag === "seen") {
				return row.getAttribute("data-seen") === "true" ? "false" : "true";
			}
			if (flag === "flagged") {
				return row.getAttribute("data-flagged") === "true" ? "false" : "true";
			}
			return row.getAttribute("data-erledigt") === "true" ? "false" : "true";
		}

		function stripe() {
			var rows = table.tBodies[0].rows;
			for (var i = 0; i < rows.length; i++) {
				var unread = rows[i].getAttribute("data-seen") === "true" ? "" : " unread";
				var flagged = rows[i].getAttribute("data-flagged") === "true" ? " flagged" : "";
				var other = rows[i].getAttribute("data-year") === "false" ? " other-year" : "";
				rows[i].className = (i % 2 === 0 ? "even" : "odd") + unread + flagged + other;
			}
		}

		function sortBy(key) {
			sortDir = sortKey === key && sortDir === "asc" ? "desc" : "asc";
			sortKey = key;
			var body = table.tBodies[0];
			var rows = Array.prototype.slice.call(body.rows);
			rows.sort(function (a, b) {
				var av = cell(a, key).getAttribute("data-v") || "";
				var bv = cell(b, key).getAttribute("data-v") || "";
				var an = Number(av);
				var bn = Number(bv);
				var result = av !== "" && bv !== "" && String(an) === av && String(bn) === bv
					? an - bn
					: av.localeCompare(bv, "de");
				return sortDir === "asc" ? result : -result;
			});
			rows.forEach(function (row) { body.appendChild(row); });
			stripe();
			var headers = table.tHead.rows[0].cells;
			for (var i = 0; i < headers.length; i++) {
				var link = headers[i].querySelector("a");
				if (!link) {
					continue;
				}
				var label = link.getAttribute("data-label");
				link.textContent = link.getAttribute("data-key") === key
					? label + (sortDir === "asc" ? " ↑" : " ↓")
					: label;
			}
		}

		function renderParties(query) {
			var list = document.getElementById("party-results");
			var needle = query.toLowerCase();
			list.innerHTML = "";
			var items = document.querySelectorAll("#party-index li");
			var count = 0;
			for (var i = 0; i < items.length; i++) {
				var search = (items[i].getAttribute("data-search") || "").toLowerCase();
				if (needle !== "" && search.indexOf(needle) < 0) {
					continue;
				}
				count += 1;
				if (count > 30) {
					break;
				}
				var choice = document.createElement("li");
				var link = document.createElement("a");
				link.href = "#verlinken";
				link.textContent = items[i].getAttribute("data-role") + ": " + items[i].getAttribute("data-name");
				link.setAttribute("data-id", items[i].getAttribute("data-id"));
				choice.appendChild(link);
				list.appendChild(choice);
			}
			if (count === 0) {
				var empty = document.createElement("li");
				empty.textContent = "Kein Debitor oder Kreditor gefunden.";
				list.appendChild(empty);
			}
		}

		table.addEventListener("click", function (event) {
			var target = event.target.closest ? event.target.closest("a") : null;
			if (!target || !table.contains(target)) {
				return;
			}
			if (target.getAttribute("data-key")) {
				event.preventDefault();
				sortBy(target.getAttribute("data-key"));
				return;
			}
			var state = target.className.indexOf("state-link") >= 0 ? target : null;
			if (state) {
				event.preventDefault();
				stateRow = target.closest("tr");
				stateFlag = target.getAttribute("data-flag");
				stateNext = nextValue(stateFlag, stateRow);
				document.getElementById("state-text").textContent = question(stateFlag, stateRow);
				document.getElementById("state-error").textContent = "";
				show("state-dialog");
				hide("link-dialog");
				return;
			}
			if (target.className.indexOf("link-party") >= 0) {
				event.preventDefault();
				linkEmail = target.getAttribute("data-email") || "";
				var domain = target.getAttribute("data-domain") || "";
				var query = document.getElementById("party-query");
				query.value = domain;
				renderParties(domain);
				show("link-dialog");
				hide("state-dialog");
				query.focus();
			}
		});

		document.getElementById("state-close").addEventListener("click", function (event) {
			event.preventDefault();
			hide("state-dialog");
		});
		document.getElementById("link-close").addEventListener("click", function (event) {
			event.preventDefault();
			hide("link-dialog");
		});
		document.getElementById("state-apply").addEventListener("click", function (event) {
			event.preventDefault();
			if (!stateRow) {
				return;
			}
			var url = table.getAttribute("data-api") + "/" + stateRow.getAttribute("data-number") + "?folder=INBOX&" + stateFlag + "=" + stateNext;
			fetch(url, { method: "PUT", credentials: "same-origin", headers: { "Accept": "application/xml" } })
				.then(function (response) { return response.text(); })
				.then(function (text) {
					var doc = new DOMParser().parseFromString(text, "application/xml");
					var error = doc.getElementsByTagName("error")[0];
					if (error) {
						document.getElementById("state-error").textContent = error.textContent;
						return;
					}
					var flags = doc.getElementsByTagName("flag");
					var seen = stateRow.getAttribute("data-seen");
					var flagged = stateRow.getAttribute("data-flagged");
					var done = stateRow.getAttribute("data-erledigt");
					for (var i = 0; i < flags.length; i++) {
						var name = flags[i].getAttribute("name");
						var value = flags[i].getAttribute("value");
						if (name === "seen") seen = value;
						if (name === "flagged") flagged = value;
						if (name === "erledigt") done = value;
					}
					paint(stateRow, seen, flagged, done);
					hide("state-dialog");
				})
				.catch(function () {
					document.getElementById("state-error").textContent = "Der Status konnte nicht gespeichert werden.";
				});
		});
		document.getElementById("party-query").addEventListener("input", function (event) {
			renderParties(event.target.value);
		});
		document.getElementById("party-results").addEventListener("click", function (event) {
			var target = event.target.closest ? event.target.closest("a") : null;
			if (!target) {
				return;
			}
			event.preventDefault();
			document.getElementById("link-account").value = target.getAttribute("data-id");
			document.getElementById("link-email").value = linkEmail;
			document.getElementById("link-form").submit();
		});

		sortBy("number");
	});
}());
