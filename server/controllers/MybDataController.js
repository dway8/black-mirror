const GetCurrentMybDataAndOpenings = require("../application/use_cases/mybData/GetCurrentMybDataAndOpenings");
const HandleMybEvent = require("../application/use_cases/mybData/HandleMybEvent");
const UpdateMybData = require("../application/use_cases/mybData/UpdateMybData");

module.exports = dependencies => {
    const {
        mybDataRepository,
        mybOpeningRepository,
    } = dependencies.DatabaseService;
    const { LoggerService, SSEService } = dependencies;

    const getCurrentMybDataAndOpenings = (_req, res, next) => {
        const GetCurrentMybDataAndOpeningsCommand = GetCurrentMybDataAndOpenings(
            mybDataRepository,
            mybOpeningRepository,
            LoggerService
        );

        GetCurrentMybDataAndOpeningsCommand.Execute().then(
            response => {
                res.json({ success: true, data: response });
            },
            err => {
                next(err);
            }
        );
    };

    const handleMybEvent = (req, _res, _next) => {
        //         res.send({ message: "OK" });
        const HandleMybEventCommand = HandleMybEvent(
            mybDataRepository,
            mybOpeningRepository,
            SSEService,
            LoggerService
        );
        HandleMybEventCommand.Execute(req.body);
    };

    const updateMybData = (req, res, next) => {
        const UpdateMybDataCommand = UpdateMybData(
            mybDataRepository,
            LoggerService
        );
        const { title, content } = req.body;
        UpdateMybDataCommand.Execute({ title, content }).then(
            response => {
                res.json({ success: true, data: response });
            },
            err => {
                next(err);
            }
        );
    };

    return {
        getCurrentMybDataAndOpenings,
        handleMybEvent,
        updateMybData,
    };
};
