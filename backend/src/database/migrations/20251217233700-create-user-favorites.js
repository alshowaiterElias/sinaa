'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('user_favorites', {
            id: {
                type: Sequelize.INTEGER,
                primaryKey: true,
                autoIncrement: true,
            },
            user_id: {
                type: Sequelize.INTEGER,
                allowNull: false,
                references: {
                    model: 'users',
                    key: 'id',
                },
                onUpdate: 'CASCADE',
                onDelete: 'CASCADE',
            },
            project_id: {
                type: Sequelize.INTEGER,
                allowNull: false,
                references: {
                    model: 'projects',
                    key: 'id',
                },
                onUpdate: 'CASCADE',
                onDelete: 'CASCADE',
            },
            created_at: {
                type: Sequelize.DATE,
                allowNull: false,
                defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
            },
        });

        // Unique constraint to prevent duplicate favorites
        await queryInterface.addIndex('user_favorites', ['user_id', 'project_id'], {
            unique: true,
            name: 'user_favorites_user_project_unique',
        });

        // Index for faster lookups
        await queryInterface.addIndex('user_favorites', ['user_id']);
        await queryInterface.addIndex('user_favorites', ['project_id']);
    },

    async down(queryInterface) {
        await queryInterface.dropTable('user_favorites');
    },
};
