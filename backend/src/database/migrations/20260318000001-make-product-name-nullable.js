'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn('products', 'name', {
      type: Sequelize.STRING(200),
      allowNull: true,
    });
    await queryInterface.changeColumn('products', 'description', {
      type: Sequelize.TEXT,
      allowNull: true,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.changeColumn('products', 'name', {
      type: Sequelize.STRING(200),
      allowNull: false,
    });
  },
};
