'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('categories', 'status', {
            type: Sequelize.ENUM('active', 'inactive', 'pending', 'rejected'),
            defaultValue: 'active',
            allowNull: false,
        });

        await queryInterface.addColumn('categories', 'created_by', {
            type: Sequelize.INTEGER,
            allowNull: true,
            references: {
                model: 'users',
                key: 'id',
            },
            onUpdate: 'CASCADE',
            onDelete: 'SET NULL',
        });

        await queryInterface.addColumn('categories', 'rejection_reason', {
            type: Sequelize.STRING(255),
            allowNull: true,
        });

        // Index for status to speed up filtering
        await queryInterface.addIndex('categories', ['status']);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeIndex('categories', ['status']);
        await queryInterface.removeColumn('categories', 'rejection_reason');
        await queryInterface.removeColumn('categories', 'created_by');
        await queryInterface.removeColumn('categories', 'status');
    }
};
