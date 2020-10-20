module.exports = (MybDataRepository, MybOpeningRepository) => {
    async function Execute() {
        const mybData = await MybDataRepository.getCurrent();
        mybData.openings = await MybOpeningRepository.getAll();

        return mybData;
    }

    return { Execute };
};
