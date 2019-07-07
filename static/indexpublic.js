"use strict";

var { Elm } = require("../src/Public/Main.elm");
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
            audio = new Audio(
                "http://54.36.52.224:42424/sounds/cashregister.mp3"
            );
            audio.play();
            break;
        case "playFanfare":
            audio = new Audio("http://54.36.52.224:42424/sounds/fanfare.wav");
            audio.play();
            break;
        case "playKnock":
            audio = new Audio("http://54.36.52.224:42424/sounds/knock.wav");
            audio.play();
            break;

        default:
            console.log("Unrecognized type");
            break;
    }
});
