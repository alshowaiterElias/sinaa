'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('projects', 'disable_reason', {
            type: Sequelize.TEXT,
            allowNull: true,
            after: 'status'
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeColumn('projects', 'disable_reason');
    }
};
