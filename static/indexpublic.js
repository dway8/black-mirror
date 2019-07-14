"use strict";
var { Elm } = require("../src/Public/Main.elm");
var createEventSource = require("../libraries/sse");
var common = require("../libraries/common");

var node = document.getElementById("content");

var now = new Date().getTime();
var viewport = {
    width: window.innerWidth,
    height: window.innerHeight,
};
var app = Elm.Public.Main.init({
    node,
    flags: { now, viewport },
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

var es;
createEventSource(es, app, "/api/sse");
