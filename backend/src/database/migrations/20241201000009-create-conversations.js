'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('conversations', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      customer_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      project_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'projects',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      last_message_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    // Add unique constraint for customer_id + project_id
    await queryInterface.addIndex('conversations', ['customer_id', 'project_id'], {
      unique: true,
      name: 'unique_conversation',
    });

    // Add indexes
    await queryInterface.addIndex('conversations', ['customer_id']);
    await queryInterface.addIndex('conversations', ['project_id']);
    await queryInterface.addIndex('conversations', ['last_message_at']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('conversations');
  },
};

