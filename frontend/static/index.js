"use strict";

var { Elm } = require("../src/Main.elm");
// var ephemeris = require('../elm/libs/ephemeris.js');
var node = document.getElementById("content");

var now = new Date().getTime();
var viewport = {
    width: window.innerWidth,
    height: window.innerHeight,
};
var app = Elm.Main.init({
    node,
    flags: { now, viewport },
});

app.ports.infoForOutside.subscribe(function(elmData) {
    var tag = elmData.tag;
    switch (tag) {
        case "playCashRegister":
            var audio = new Audio(
                "http://54.36.52.224:42424/sounds/cashregister.mp3"
            );
            audio.play();
            break;
        case "playFanfare":
            var audio = new Audio(
                "http://54.36.52.224:42424/sounds/fanfare.wav"
            );
            audio.play();
            break;
        case "playKnock":
            var audio = new Audio("http://54.36.52.224:42424/sounds/knock.wav");
            audio.play();
            break;

        default:
            console.log("Unrecognized type");
            break;
    }
});
