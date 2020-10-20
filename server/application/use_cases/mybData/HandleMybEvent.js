module.exports = (MybDataRepository, MybOpeningRepository, SSEService) => {
    async function Execute(params) {
        const event = params.event;

        let {
            id,
            todayUsers,
            yearUsers,
            totalUsers,
        } = await MybDataRepository.getCurrent();

        switch (event) {
            case "new_user":
                todayUsers++;
                yearUsers++;
                totalUsers++;

                await MybDataRepository.updateTodayData(
                    { totalUsers, todayUsers, yearUsers },
                    id
                );
                break;
            // case "new_order":
            //     if (params.amount) {
            //         await handleNewOrder(params);
            //     }
            //     break;
            // case "order_cancelled":
            //     if (params.amount) {
            //         await handleOrderCancelled(params);
            //     }
            //     break;
            // case "new_exhibitor":
            //     await handleNewExhibitor();
            //     break;
            // case "new_prod_occurrence":
            //     await handleNewProdOccurrence(params);
            //     break;
            // case "new_open_occurrence":
            //     await handleNewOpenOccurrence();
            //     break;
            // case "user_deleted":
            //     await handleUserDeleted(params);
            //     break;
            default:
                // winston.error("Unknown event", { event });
                break;
        }

        const newMybData = await MybDataRepository.getCurrent();
        newMybData.openings = await MybOpeningRepository.getAll();

        await SSEService.notify({
            data: { data: newMybData, event },
            event: "MYB-event",
        });

        return;
    }

    return { Execute };
};
