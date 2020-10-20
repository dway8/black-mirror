module.exports = (MessageRepository, SSEService) => {
    async function Execute(id) {
        await MessageRepository.delete(id);

        const messages = await MessageRepository.getAll();

        await SSEService.notify({
            data: { messages },
            event: "messages-event",
        });

        return messages;
    }

    return { Execute };
};
