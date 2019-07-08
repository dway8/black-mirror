"use strict";

var { Elm } = require("../src/Public/Main.elm");
var createEventSource = require("../libraries/sse");

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
    let audio;
    switch (tag) {
        case "playCashRegister":
            audio = new Audio("sounds/cashregister.mp3");
            audio.play();
            break;
        case "playKnock":
            audio = new Audio("sounds/knock.wav");
            audio.play();
            break;

        // case "playFanfare":
        //     audio = new Audio("sounds/fanfare.wav");
        //     audio.play();
        //     break;

        default:
            console.log("Unrecognized type");
            break;
    }
});

var es;
createEventSource(es, app, "/api/sse");
