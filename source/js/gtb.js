function exportResult(url, clientFilename, mimetype) {
    $.ajax({
        url: url,
        success: download.bind(true, mimetype, clientFilename)
    });
}

function openNewWindow(url) {
    window.open(url);
}

function hasOwnProperty(object, property) {
    return object.hasOwnProperty(property);
}