function exportResult(url, clientFilename, mimetype) {
    //window.open(url, "_blank");
    $.ajax({
		url: url, 
		success: download.bind(true, mimetype, clientFilename)
	});
}