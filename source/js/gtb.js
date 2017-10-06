$(document).ready(function init() {
    // This code was stolen from the IVDNT anw application and adapted for GTB purposes.
    
    // Initialise bootstrap3-typeahead.js (for autosuggest in simple search)
    // (this is basically the old bootstrap2 typeahead ported to bootstrap 3.
    // we use this instead of twitter-typeahead / bloodhound that wasn't working
    // for us (messed up layout, asynchronous AJAX queries not working, ...)
    
    function getWdbsAndSensitivityParams(htmlObject) {
        var tabDiv = $(htmlObject).closest(".tab-pane");
        var sensitivity = $(tabDiv).find("input[data-inputname=sensitive]:checked");
        var isSensitive = sensitivity.length > 0;
        var wdbArray = [];
        $(tabDiv).find("input[data-inputname=wdb]:checked").each(function () {
            wdbArray.push(this.getAttribute("name"));
        });
        return "wdb=" + encodeURIComponent(wdbArray.join(",")) + "&sensitive=" + isSensitive;
    }
    
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
                var extraParams = getWdbsAndSensitivityParams(htmlObject);
                // Constant BASE_LIST_URL has been defined globally in the main HTML file
                // TODO wdb-parameter toevoegen
                var url = BASE_LIST_URL + "&index=" + name + "&prefix=" + encodeURIComponent(query) + "&" + extraParams;
                //console.log("url=" + url);
                
                var results =[];
                $. get (url,
                function (data) {
                    /* Sample XML file:
                    <wdbData prefixLength='3'>
                    <result prefixLength='3' Lemma="koe" Wdb="VMNW,WFT,ONW,WNT,MNW"/>
                    <result prefixLength='3' Lemma="koeaal" Wdb="WNT"/>
                    </wdbData>
                     */
                    $(data).find('result').each(function () {
                        var result = this.getAttribute("Lemma");
                        var wdb = this.getAttribute("Wdb");
                        results.push('<span class="gtb-typeahead-word">' + result + '</span>' + '<span class="gtb-typeahead-wdb">' + wdb + '</span>');
                    });
                    process(results);
                },
                "xml");
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
            
            // When an item is selected, we just take the word, not the wdbs.
            select: function () {
                var val = this.$menu.find('.active').data('value');
                this.$element.data('active', val);
                if (this.autoSelect || val) {
                    var newVal = this.updater(val);
                    // Updater can be set to any random functions via "options" parameter in constructor above.
                    // Add null check for cases when updater returns void or undefined.
                    if (! newVal) {
                        newVal = '';
                    }
                    // Delete all from newVal except the content of the first <span>
                    newVal = newVal.replace(/^<span[^>]*>([^<]*)<.*$/, "$1");

                    this.$element.val(this.displayText(newVal) || newVal).text(this.displayText(newVal) || newVal).change();
                    this.afterSelect(newVal);
                }
                return this.hide();
            },
            
            // What to do after a word is selected.
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