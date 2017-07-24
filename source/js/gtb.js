function exportResult(url, clientFilename, mimetype) {
    $.ajax({
		url: url, 
		success: download.bind(true, mimetype, clientFilename)
	});
}
