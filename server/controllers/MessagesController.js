const AddMessage = require("../application/use_cases/messages/AddMessage");
const GetActiveMessages = require("../application/use_cases/messages/GetActiveMessages");
const GetAllMessages = require("../application/use_cases/messages/GetAllMessages");
const ArchiveMessage = require("../application/use_cases/messages/ArchiveMessage");
const DeleteMessage = require("../application/use_cases/messages/DeleteMessage");

module.exports = dependencies => {
    const { messageRepository } = dependencies.DatabaseService;
    const { SSEService, LoggerService } = dependencies;

    const addNewMessage = (req, res, next) => {
        // init use case
        const AddMessageCommand = AddMessage(
            messageRepository,
            SSEService,
            LoggerService
        );
        // extract message properties
        const { title, content } = req.body;
        // call use case
        AddMessageCommand.Execute({ title, content }).then(
            response => {
                res.json({ success: true, data: response });
            },
            err => {
                next(err);
            }
        );
    };

    const getActiveMessages = (_req, res, next) => {
        // init use case
        const GetActiveMessagesQuery = GetActiveMessages(
            messageRepository,
            LoggerService
        );

        GetActiveMessagesQuery.Execute().then(
            messages => {
                res.json({ success: true, data: messages });
            },
            err => {
                next(err);
            }
        );
    };

    const getAllMessages = (_req, res, next) => {
        // init use case
        const GetAllMessagesQuery = GetAllMessages(messageRepository);

        GetAllMessagesQuery.Execute().then(
            messages => {
                res.json({ success: true, data: messages });
            },
            err => {
                next(err);
            }
        );
    };

    const archiveMessage = (req, res, next) => {
        const ArchiveMessageCommand = ArchiveMessage(messageRepository);

        ArchiveMessageCommand.Execute(req.params.id).then(
            response => {
                res.json({ success: true, data: response });
            },
            err => {
                next(err);
            }
        );
    };

    const deleteMessage = (req, res, next) => {
        const DeleteMessageCommand = DeleteMessage(messageRepository);

        DeleteMessageCommand.Execute(req.params.id).then(
            response => {
                res.json({ success: true, data: response });
            },
            err => {
                next(err);
            }
        );
    };

    return {
        addNewMessage,
        getActiveMessages,
        getAllMessages,
        archiveMessage,
        deleteMessage,
    };
};
