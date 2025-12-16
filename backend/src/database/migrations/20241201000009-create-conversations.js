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
      user1_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
        comment: 'Normalized: always the smaller user ID',
      },
      user2_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
        comment: 'Normalized: always the larger user ID',
      },
      project_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'projects',
          key: 'id',
        },
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
        comment: 'Optional: context for product-related chats',
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

    // Add unique constraint on user pair (ensures one conversation per user pair)
    await queryInterface.addIndex('conversations', ['user1_id', 'user2_id'], {
      unique: true,
      name: 'unique_user_pair',
    });

    // Add indexes for queries
    await queryInterface.addIndex('conversations', ['user1_id']);
    await queryInterface.addIndex('conversations', ['user2_id']);
    await queryInterface.addIndex('conversations', ['project_id']);
    await queryInterface.addIndex('conversations', ['last_message_at']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('conversations');
  },
};
