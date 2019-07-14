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

module.exports = { playAudio };
