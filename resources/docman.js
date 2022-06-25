function deleteData(url) {
	const method = "DELETE";

	fetch(url, { method: method} )
		.then((response) => {
			console.info("Request suceeded", response);
			setTimeout(location.reload(), 1000);
		})
		.catch((err) => {
			console.error("Error running Request", err);
		})
}