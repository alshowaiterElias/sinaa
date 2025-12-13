'use strict';

const bcrypt = require('bcryptjs');

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Hash password (default: Admin@123)
    const passwordHash = await bcrypt.hash('Admin@123', 12);

    await queryInterface.bulkInsert('users', [
      {
        email: 'admin@sinaa.sa',
        password_hash: passwordHash,
        phone: '+966500000000',
        full_name: 'مدير النظام',
        avatar_url: null,
        role: 'admin',
        language: 'ar',
        is_active: true,
        is_banned: false,
        ban_reason: null,
        refresh_token: null,
        created_at: new Date(),
        updated_at: new Date(),
      },
    ]);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('users', { email: 'admin@sinaa.sa' }, {});
  },
};

