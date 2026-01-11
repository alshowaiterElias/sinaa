'use strict';

// Password hash for: 12345678aA!
const PASSWORD_HASH = '$2a$12$TI0PvVvXF.yhOP4bs/pPseGtmwPrMYc1RMRVPyj2IK76GGn0O9ZAla';
// Admin password hash (keep original: Admin@123!)
const ADMIN_PASSWORD_HASH = '$2a$12$QIyz4CjP0jNQja9BONS8uOKXh6s8J40vq7dxtvO5OWQ8txpLc8t2S';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.bulkInsert('users', [
      {
        id: 2,
        email: 'alshowaiterelias@gmail.com',
        password_hash: PASSWORD_HASH,
        phone: '0512345678',
        full_name: 'Elias Al-Showaiter',
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
        password_hash: ADMIN_PASSWORD_HASH, // Keep admin password unchanged
        phone: '+966500000000',
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
        email: 'alshowaiterelias1@gmail.com',
        password_hash: PASSWORD_HASH,
        phone: '0512345677',
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
        email: 'maria@gmail.com',
        password_hash: PASSWORD_HASH,
        phone: '0512345676',
        full_name: 'Maria Alsoufi',
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
