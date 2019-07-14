var backoff = 0;
function createEventSource(es, app, url) {
    if (window.EventSource) {
        es = new EventSource(url);

        es.addEventListener("MYB-event", function(event) {
            var res = {
                tag: "receivedMYBEvent",
                data: JSON.parse(event.data),
            };
            app.ports.infoForElm.send(res);
        });

        es.addEventListener("messages-event", function(event) {
            var res = {
                tag: "receivedMessages",
                data: JSON.parse(event.data),
            };
            app.ports.infoForElm.send(res);
        });

        es.addEventListener(
            "error",
            function(e) {
                var wait = Math.pow(2, backoff);
                backoff += 1;
                setTimeout(function() {
                    if (e.currentTarget.readyState === EventSource.CLOSED) {
                        createEventSource(es, app, url);
                    }
                }, wait * 1000);
                console.log(
                    "Connection to SSE lost; waiting " +
                        wait +
                        " seconds to reconnect."
                );
            },
            false
        );

        es.addEventListener(
            "open",
            function() {
                backoff = 0;
            },
            false
        );
    }
}

module.exports = createEventSource;
