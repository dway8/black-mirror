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
    switch (tag) {
        case "playCashRegister":
            playAudio("sounds/cashregister.mp3");
            break;
        case "playKnock":
            playAudio("sounds/knock.wav");
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

function playAudio(url) {
    const audio = new Audio(url);
    const playPromise = audio.play();
    if (playPromise !== undefined) {
        playPromise
            .then(() => {
                // Audio started!
            })
            .catch(e => {
                console.log("Error playing audio", e);
            });
    }
}

var es;
createEventSource(es, app, "/api/sse");
