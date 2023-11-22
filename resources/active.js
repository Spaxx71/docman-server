// https://jsonplaceholder.typicode.com/posts

async function fetchPosts(apiUrl) {
    try {
        //console.log("url:", apiUrl);

        const response = await fetch(apiUrl);
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }
        const json = await response.json();
        return json;
    } catch (e) {
        console.log('Error fetchPosts:', e);
    }
}

function listMessages(apiUrl, postContainerElementId) {
    const postContainerElement = document.getElementById(`${postContainerElementId}`);

    const url = window.location.origin + `${apiUrl}`;

    if (!postContainerElement) {
        return;
    }

    // because fetchPosts returns a promise, use then() to get content and catch() in case of any error, e.g. if messages are not iterable
    fetchPosts(url)
        .then((messages) => {
            if (!messages) {
                console.log('No message from url:', url);
                postContainerElement.innerText = "Aktuell keine neuen HBCI+/FinTS Nachrichten";
            }
            else {
                console.log(messages);
                postContainerElement.removeChild;
                for (const message of messages) {
                    const messageElement = document.createElement('div');
                    messageElement.innerText = message.timestamp + ": " + message.text;
                    postContainerElement.appendChild(messageElement);
                }
            }
        })
        .catch((e) => {
            postContainerElement.innerText = "ERROR: Could not read messages from '"+ url +"'. Reason: '" + e + "'";
            console.log('Error: listMessages:', e);
        });
}
