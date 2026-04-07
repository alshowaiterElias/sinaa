'use strict';

// Password hash for: 12345678aA!
const PASSWORD_HASH = '$2a$12$JeR.e6HPOyz/Wp20dRhaNOFUDuX4rx491DtPwmJIcj/PUixiGh68i';
// Admin password hash (keep original: Admin@123!)
const ADMIN_PASSWORD_HASH = '$2a$12$rTN6H24oDEvonv81ZRpRbe3ELC1NcbJYlXhDRF6EqLhyvth3t05f2';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.bulkInsert('users', [
      {
        id: 2,
        email: 'Test1@gmail.com',
        password_hash: PASSWORD_HASH,
        phone: '712345678',
        full_name: 'Test',
        avatar_url: null,
        city: 'Riyadh',
        latitude: 24.7136,
        longitude: 46.6753,
        location_sharing_enabled: true,
        location_updated_at: new Date(),
        role: 'project_owner',
        language: 'ar',
        is_active: true,
        is_banned: false,
        ban_reason: null,
        refresh_token: null,
        created_at: new Date(),
        updated_at: new Date(),
      },
      {
        id: 3,
        email: 'admin@sinaa.sa',
        password_hash: ADMIN_PASSWORD_HASH, // Keep admin password unchanged Admin@123
        phone: '712345677',
        full_name: 'مدير النظام',
        avatar_url: null,
        city: 'Riyadh',
        latitude: 24.7136,
        longitude: 46.6753,
        location_sharing_enabled: false,
        location_updated_at: new Date(),
        role: 'admin',
        language: 'ar',
        is_active: true,
        is_banned: false,
        ban_reason: null,
        refresh_token: null,
        created_at: new Date(),
        updated_at: new Date(),
      },
      {
        id: 4,
        email: 'Test5@gmail.com',
        password_hash: PASSWORD_HASH,
        phone: '712345677',
        full_name: 'Customer',
        avatar_url: null,
        city: 'Jeddah',
        latitude: 21.5433,
        longitude: 39.1728,
        location_sharing_enabled: true,
        location_updated_at: new Date(),
        role: 'customer',
        language: 'ar',
        is_active: true,
        is_banned: false,
        ban_reason: null,
        refresh_token: null,
        created_at: new Date(),
        updated_at: new Date(),
      },
      {
        id: 5,
        email: 'Test3@gmail.com',
        password_hash: PASSWORD_HASH,
        phone: '712345676',
        full_name: 'Test3',
        avatar_url: null,
        city: 'Dammam',
        latitude: 26.4207,
        longitude: 50.0888,
        location_sharing_enabled: true,
        location_updated_at: new Date(),
        role: 'project_owner',
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
    await queryInterface.bulkDelete('users', { id: [2, 3, 4, 5] }, {});
  },
};
