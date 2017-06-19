<?php

$baseURL = "http://gtb.inl.nl/iWDB/search";
$queryString = $_SERVER['QUERY_STRING'];
$fullURL = $baseURL . "?" . $queryString;

# %5F%5Flzbc%5F%5F=1496155576121%2E01&actie=results&lemmodern=koe&domein=0&wdb=onw%2Cvmnw%2Cmnw%2Cwnt%2Cwft&conc=true&sensitive=false&xmlerror=true
# http://gtb.inl.nl/iWDB/search?%5F%5Flzbc%5F%5F=1496155576121%2E01&actie=results&lemmodern=koe&domein=0&wdb=onw%2Cvmnw%2Cmnw%2Cwnt%2Cwft&conc=true&sensitive=false&xmlerror=true
# http://localhost/redirect.php?%5F%5Flzbc%5F%5F=1496155576121%2E01&actie=results&lemmodern=koe&domein=0&wdb=onw%2Cvmnw%2Cmnw%2Cwnt%2Cwft&conc=true&sensitive=false&xmlerror=true

#error_log("redirect naar: " . $fullURL);

$handle = fopen($fullURL, "rb");
if (FALSE === $handle) {
    exit("Failed to open stream to URL " . $fullURL);
}

while (!feof($handle)) {
    $chunk = fread($handle, 8192);
    print $chunk;
}

fclose($handle);

?>
