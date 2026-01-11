'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // Add location columns to users table
        await queryInterface.addColumn('users', 'city', {
            type: Sequelize.STRING(100),
            allowNull: true,
            after: 'avatar_url'
        });

        await queryInterface.addColumn('users', 'latitude', {
            type: Sequelize.DECIMAL(10, 8),
            allowNull: true,
            after: 'city'
        });

        await queryInterface.addColumn('users', 'longitude', {
            type: Sequelize.DECIMAL(11, 8),
            allowNull: true,
            after: 'latitude'
        });

        await queryInterface.addColumn('users', 'location_sharing_enabled', {
            type: Sequelize.BOOLEAN,
            defaultValue: true,
            allowNull: false,
            after: 'longitude',
            comment: 'User preference for location-based features'
        });

        await queryInterface.addColumn('users', 'location_updated_at', {
            type: Sequelize.DATE,
            allowNull: true,
            after: 'location_sharing_enabled'
        });

        // Add composite index for location queries
        await queryInterface.addIndex('users', ['latitude', 'longitude'], {
            name: 'users_location_idx'
        });

        // Add index for city filtering
        await queryInterface.addIndex('users', ['city'], {
            name: 'users_city_idx'
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeIndex('users', 'users_city_idx');
        await queryInterface.removeIndex('users', 'users_location_idx');
        await queryInterface.removeColumn('users', 'location_updated_at');
        await queryInterface.removeColumn('users', 'location_sharing_enabled');
        await queryInterface.removeColumn('users', 'longitude');
        await queryInterface.removeColumn('users', 'latitude');
        await queryInterface.removeColumn('users', 'city');
    }
};
