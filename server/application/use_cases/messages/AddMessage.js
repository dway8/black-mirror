const Message = require("../../../domain/entities/Message");

module.exports = (MessageRepository, SSEService) => {
    async function Execute({ title, content }) {
        const newMessage = new Message({ title, content });
        await MessageRepository.add(newMessage);

        const messages = await MessageRepository.getActive();

        await SSEService.notify({
            data: { messages, isNew: true },
            event: "messages-event",
        });

        return messages;
    }

    return { Execute };
};
