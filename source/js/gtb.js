function exportResult(url, clientFilename, mimetype) {
    //window.open(url, "_blank");
    download(url, clientFilename, mimetype);
}

//function openWindow(url) {
//    var form = document.getElementById("exportform");
//    alert(url);
//    form.baseURI = url;
//    alert(form.action);
//    form.submit();
//}