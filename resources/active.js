// HBCI/FinTS message polling and challenge rendering

async function fetchPosts(apiUrl) {
    try {
        const response = await fetch(apiUrl);
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }
        return await response.json();
    } catch (e) {
        console.log('Error fetchPosts:', e);
    }
}

function renderChallengeHtml(text) {
    if (!text) {
        return '';
    }
    // Structured Challenge XML from bridge
    if (text.indexOf('<Challenge') >= 0) {
        try {
            const doc = new DOMParser().parseFromString(text, 'application/xml');
            const challenge = doc.querySelector('Challenge');
            if (!challenge) {
                return escapeHtml(text);
            }
            const type = challenge.getAttribute('type') || 'text';
            const msg = (challenge.querySelector('text') || {}).textContent || '';
            const hhduc = (challenge.querySelector('hhduc') || {}).textContent || '';
            const svgNode = challenge.querySelector('svg');
            let svg = '';
            if (svgNode) {
                svg = svgNode.textContent || '';
                // CDATA may leave the raw svg markup as textContent
            }
            const fallback = challenge.querySelector('fallback');
            let media = '';
            if (svg && svg.indexOf('<svg') >= 0) {
                media = `<div class="tan-challenge tan-challenge-${type}">${svg}</div>`;
            } else if (fallback && fallback.textContent) {
                const mime = fallback.getAttribute('mediaType') || 'image/png';
                media = `<div class="tan-challenge tan-challenge-${type}"><img alt="${type}" src="data:${mime};base64,${fallback.textContent.trim()}" style="max-width:280px;background:#fff;padding:8px;"/></div>`;
            }
            const hhducHint = hhduc ? `<div class="tan-hhduc" style="font-size:11px;opacity:.7;word-break:break-all;">HHD: ${escapeHtml(hhduc)}</div>` : '';
            return `<div class="tan-block"><strong>${escapeHtml(type.toUpperCase())}</strong><div>${escapeHtml(msg)}</div>${media}${hhducHint}</div>`;
        } catch (e) {
            console.log('Challenge parse error', e);
            return escapeHtml(text);
        }
    }
    return escapeHtml(text);
}

function escapeHtml(s) {
    return String(s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function listMessages(apiUrl, postContainerElementId) {
    const postContainerElement = document.getElementById(`${postContainerElementId}`);
    const url = window.location.origin + `${apiUrl}`;

    if (!postContainerElement) {
        return;
    }

    fetchPosts(url)
        .then((messages) => {
            if (!messages) {
                console.log('No message from url:', url);
                postContainerElement.innerText = "Aktuell keine neuen HBCI+/FinTS Nachrichten";
            }
            else {
                postContainerElement.innerHTML = '';
                const list = Array.isArray(messages) ? messages : [messages];
                for (const message of list) {
                    const messageElement = document.createElement('div');
                    messageElement.className = 'hbci-message';
                    const ts = message.timestamp || '';
                    const body = message.text || message.challenge || '';
                    messageElement.innerHTML = `<div class="hbci-ts">${escapeHtml(ts)}</div>${renderChallengeHtml(body)}`;
                    postContainerElement.appendChild(messageElement);
                }
            }
        })
        .catch((e) => {
            postContainerElement.innerText = "ERROR: Could not read messages from '"+ url +"'. Reason: '" + e + "'";
            console.log('Error: listMessages:', e);
        });
}

/**
 * After process save: execute draft SepaTransferTask if present.
 * opts: { apiBase, tenant, year, processId, bankAccountHint }
 */
async function executeSepaTransferAfterSave(opts) {
    const panel = document.getElementById('sepa-transfer-panel');
    if (panel) {
        panel.style.display = 'block';
        panel.innerHTML = '<p>SEPA-Überweisung wird vorbereitet… Bitte ggf. TAN freigeben.</p><div id="hbci-message-container" style="min-height:8rem;border:1px solid #444;padding:6px;"></div>';
    }
    const url = `${opts.apiBase}/tenants/${opts.tenant}/years/${opts.year}/binders/${opts.binder}/documents/${opts.processId}/sepa-transfer`;
    try {
        const response = await fetch(url, { method: 'POST', headers: { 'Accept': 'application/xml, application/json' } });
        const text = await response.text();
        if (panel) {
            panel.innerHTML += `<pre style="white-space:pre-wrap;">${escapeHtml(text)}</pre>`;
        }
        return text;
    } catch (e) {
        if (panel) {
            panel.innerHTML += `<p class="error">SEPA-Überweisung fehlgeschlagen: ${escapeHtml(String(e))}</p>`;
        }
        throw e;
    }
}
