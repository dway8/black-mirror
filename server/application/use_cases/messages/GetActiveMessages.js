module.exports = MessageRepository => {
    async function Execute() {
        const messages = await MessageRepository.getActive();

        return messages;
    }

    return { Execute };
};
