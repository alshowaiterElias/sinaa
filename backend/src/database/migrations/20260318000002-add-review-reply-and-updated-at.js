'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('reviews', 'owner_reply', {
            type: Sequelize.TEXT,
            allowNull: true,
        });
        await queryInterface.addColumn('reviews', 'owner_reply_at', {
            type: Sequelize.DATE,
            allowNull: true,
        });
        await queryInterface.addColumn('reviews', 'updated_at', {
            type: Sequelize.DATE,
            allowNull: true,
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeColumn('reviews', 'owner_reply');
        await queryInterface.removeColumn('reviews', 'owner_reply_at');
        await queryInterface.removeColumn('reviews', 'updated_at');
    },
};
