'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('users', 'is_verified', {
            type: Sequelize.BOOLEAN,
            defaultValue: false,
            allowNull: false,
        });

        await queryInterface.addColumn('users', 'verification_token', {
            type: Sequelize.STRING(255),
            allowNull: true,
        });

        await queryInterface.addColumn('users', 'verification_token_expires', {
            type: Sequelize.DATE,
            allowNull: true,
        });

        // Add index for verification token for faster lookups
        await queryInterface.addIndex('users', ['verification_token']);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeIndex('users', ['verification_token']);
        await queryInterface.removeColumn('users', 'verification_token_expires');
        await queryInterface.removeColumn('users', 'verification_token');
        await queryInterface.removeColumn('users', 'is_verified');
    },
};
