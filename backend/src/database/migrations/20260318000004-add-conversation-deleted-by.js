'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('conversations', 'deleted_by_user1', {
            type: Sequelize.BOOLEAN,
            allowNull: false,
            defaultValue: false,
        });
        await queryInterface.addColumn('conversations', 'deleted_by_user2', {
            type: Sequelize.BOOLEAN,
            allowNull: false,
            defaultValue: false,
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeColumn('conversations', 'deleted_by_user1');
        await queryInterface.removeColumn('conversations', 'deleted_by_user2');
    },
};
