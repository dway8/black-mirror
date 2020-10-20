// const Router = require("express-promise-router");
// const db = require("../db/index.js");
// const logger = require("../logger");
// const winston = logger.loggers.general;
// const { sse } = require("./sse.js");
// const messagesPort = require("../ports/messagesPort");
//
// const router = new Router();
//
// router.get("/", async (req, res) => {
//     const messages = await getActiveMessages();
//     res.send(messages);
// });
//
// router
//     .route("/admin")
//     .all(requireAuth)
//     .get(async (req, res) => {
//         const messages = await getAllMessages();
//         res.send(messages);
//     })
//     .post(async (req, res) => {
//         try {
//             const { title, content } = req.body;
//             winston.verbose("Creating a new message with params", {
//                 title,
//                 content,
//             });
//             try {
//                 await db.query(
//                     "INSERT INTO messages(title, content, active) VALUES($1, $2, $3)",
//                     [title, content, true]
//                 );
//
//                 await notifyClients(true);
//
//                 const messages = await getAllMessages();
//                 res.json({ success: true, data: messages });
//             } catch (err) {
//                 winston.error(err.stack);
//                 res.send({
//                     success: false,
//                     error: "Une erreur s'est produite",
//                 });
//             }
//         } catch (e) {
//             winston.error("Error while creating a message", { e });
//             res.send({ success: false, error: "Une erreur s'est produite" });
//         }
//     });
//
// router.get("/admin/archive/:id", requireAuth, async (req, res) => {
//     try {
//         const { id } = req.params;
//         winston.verbose(`Archiving message ${id}`);
//
//         await db.query("UPDATE messages SET active=$1 WHERE id = $2", [
//             false,
//             id,
//         ]);
//
//         await notifyClients(false);
//
//         const messages = await getAllMessages();
//         res.json({ success: true, data: messages });
//     } catch (e) {
//         winston.error("Error while archiving a message", { e });
//         res.send({ success: false, error: "Une erreur s'est produite" });
//     }
// });
//
// router.get("/admin/delete/:id", requireAuth, async (req, res) => {
//     try {
//         const { id } = req.params;
//         winston.verbose(`Deleting message ${id}`);
//
//         await db.query("DELETE FROM messages WHERE id = $1", [id]);
//
//         await notifyClients(false);
//
//         const messages = await getAllMessages();
//         res.json({ success: true, data: messages });
//     } catch (e) {
//         winston.error("Error while deleting a message", { e });
//         res.send({ success: false, error: "Une erreur s'est produite" });
//     }
// });
//
//
// module.exports = router;

const express = require("express");
const MessagesController = require("../../../controllers/MessagesController");

const messagesRouter = dependencies => {
    const router = express.Router();
    const { AuthMiddleware } = dependencies;

    const controller = MessagesController(dependencies);

    router.route("/").get(controller.getActiveMessages);

    router.route("/admin").use(AuthMiddleware.requireAuth);

    router
        .route("/admin")
        .get(controller.getAllMessages)
        .post(controller.addNewMessage);
    router.route("admin/archive/:id").get(controller.archiveMessage);
    router.route("admin/delete/:id").get(controller.deleteMessage);

    return router;
};

module.exports = messagesRouter;
