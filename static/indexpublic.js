"use strict";
var { Elm } = require("../src/Public/Main.elm");
var { createEventSource, restartSse } = require("../libraries/sse");
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
var sseUrl = "/api/sse";
es = createEventSource(es, app, sseUrl);

const oneMinute = 3000;
const keepAlive = () => {
    restartSse(es, app, sseUrl);
    setTimeout(keepAlive, oneMinute);
};
keepAlive();
