"use strict";
var { Elm } = require("../src/Admin/Main.elm");
var common = require("../libraries/common");

var node = document.getElementById("content");

var app = Elm.Admin.Main.init({
    node,
    flags: {},
});

app.ports.infoForOutside.subscribe(function(elmData) {
    let tag = elmData.tag;
    switch (tag) {
        case "playSound":
            common.playAudio(elmData.data);
            break;

        default:
            console.log("Unrecognized type");
            break;
    }
});
