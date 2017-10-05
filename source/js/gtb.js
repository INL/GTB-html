$(document).ready(function init() {
    // This code was stolen from the IVDNT anw application and adapted for GTB purposes.
    
    // Initialise bootstrap3-typeahead.js (for autosuggest in simple search)
    // (this is basically the old bootstrap2 typeahead ported to bootstrap 3.
    // we use this instead of twitter-typeahead / bloodhound that wasn't working
    // for us (messed up layout, asynchronous AJAX queries not working, ...)
    
    var typeaheads = $('.typeahead');
    typeaheads.each(function (index) {
        var htmlObject = this;
        var that = $(this);
        $(this).typeahead({
            
            // Requests suggestions from the backend
            source: function (query, process) {
                var name = htmlObject.getAttribute("name");
                query = query.replace(/^.+\s+(\S*)$/, "$1");
                if (query.length === 0) {
                    process([]);
                    return;
                }
                // Constant BASE_LIST_URL has been defined globally in the main HTML file
                // TODO wdb-parameter toevoegen
                var url = BASE_LIST_URL + "&index=" + name + "&prefix=" + encodeURIComponent(query) + "&sensitive=false";
                var results =[];
                $. get (url,
                function (data) {
                    $(data).find('result').each(function () {
                        var result = $(this).attr("Lemma");
                        results.push(result);
                    });
                    process(results);
                }, "xml");
            },
            
            // Determines what items to show (backend returns xml, we select what we need from it)
            matcher: function (item) {
                return true;
            },
            
            // Numbers of items to show (we show all items)
            items: "all",
            
            // Don't select the first suggestion
            autoSelect: false,
            
            // 300ms delay between lookups
            // (disabled, makes Enter act weird (select previous selection instead of execute search)
            //delay: 300,
            
            // Determines the value to put in the input when an item is selected.
            // We replace the last (partial) word in the input with the selected
            // word.
            updater: function (val) {
                return that.val().replace(/(^|\s+)\S+$/, "$1" + val);
            },
            
            // What to do after a word is selected. We submit the search form.
            afterSelect: function () {
                that.find(".dropdown-menu").scrollTop(0);
                //ANW.SEARCH.SIMPLE.perform();
            }
        });
    })
});

function exportResult(url, clientFilename, mimetype) {
    $.ajax({
        url: url,
        success: download.bind(true, mimetype, clientFilename)
    });
}

function openNewWindow(url) {
    window.open(url);
}