module.exports = MessageRepository => {
    async function Execute() {
        const messages = await MessageRepository.getAll();

        return messages;
    }

    return { Execute };
};
