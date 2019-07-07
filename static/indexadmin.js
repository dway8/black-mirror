"use strict";

var { Elm } = require("../src/Admin/Main.elm");
var node = document.getElementById("content");

Elm.Admin.Main.init({
    node,
    flags: {},
});
