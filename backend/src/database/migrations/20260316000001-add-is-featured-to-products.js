'use strict';

module.exports = {
    up: async (queryInterface, Sequelize) => {
        await queryInterface.addColumn('products', 'is_featured', {
            type: Sequelize.BOOLEAN,
            defaultValue: false,
            allowNull: false,
            after: 'status',
        });

        await queryInterface.addIndex('products', ['is_featured'], {
            name: 'products_is_featured',
        });
    },

    down: async (queryInterface) => {
        await queryInterface.removeIndex('products', 'products_is_featured');
        await queryInterface.removeColumn('products', 'is_featured');
    },
};
