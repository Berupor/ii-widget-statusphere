.pragma library

// .invalid is reserved (RFC 2606) and never resolves.
const urlPrefix = "https://covers.invalid/";

function url(file) {
    return urlPrefix + file;
}
