'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.bulkInsert('users', [
      {
        id: 2,
        email: 'alshowaiterelias@gmail.com',
        password_hash: '$2a$12$O3pab8qC2QpL/om9VyzNseXQrqMcLRcByu3KFVL46UYovF3S5Gzce',
        phone: '0512345678',
        full_name: 'Elias Al-Showaiter',
        avatar_url: null,
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
        password_hash: '$2a$12$QIyz4CjP0jNQja9BONS8uOKXh6s8J40vq7dxtvO5OWQ8txpLc8t2S',
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
      {
        id: 4,
        email: 'alshowaiterelias1@gmail.com',
        password_hash: '$2a$12$i6Yd7igu2EKW8fgZ8OQ36ehhn.aXkvEbDHsbvZHQSofucrv99Fb3i',
        phone: '0512345677',
        full_name: 'Customer',
        avatar_url: null,
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
        password_hash: '$2a$12$n./M2fesKjWFWrwLWYqdVuwLIWz45Q29Vbi2Z9BrMes0ar/zITchW',
        phone: '0512345676',
        full_name: 'Maria Alsoufi',
        avatar_url: null,
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
