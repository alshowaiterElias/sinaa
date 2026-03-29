'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('products', 'deleted_at', {
            type: Sequelize.DATE,
            allowNull: true,
            defaultValue: null,
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeColumn('products', 'deleted_at');
    },
};
