'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('transactions', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      conversation_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'conversations',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      product_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'products',
          key: 'id',
        },
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
        comment: 'Optional, for reference',
      },
      initiated_by: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'RESTRICT',
        onUpdate: 'CASCADE',
      },
      customer_confirmed: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      seller_confirmed: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      customer_confirmed_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      seller_confirmed_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      status: {
        type: Sequelize.ENUM('pending', 'confirmed', 'disputed', 'cancelled'),
        defaultValue: 'pending',
      },
      auto_confirm_at: {
        type: Sequelize.DATE,
        allowNull: false,
        comment: 'When to auto-confirm',
      },
      created_at: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    // Add indexes
    await queryInterface.addIndex('transactions', ['conversation_id']);
    await queryInterface.addIndex('transactions', ['product_id']);
    await queryInterface.addIndex('transactions', ['initiated_by']);
    await queryInterface.addIndex('transactions', ['status']);
    await queryInterface.addIndex('transactions', ['auto_confirm_at']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('transactions');
  },
};

