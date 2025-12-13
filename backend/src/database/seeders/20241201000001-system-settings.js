'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.bulkInsert('system_settings', [
      {
        setting_key: 'auto_confirm_days',
        setting_value: '7',
        description: 'Days before transaction auto-confirms',
        updated_at: new Date(),
      },
      {
        setting_key: 'max_product_images',
        setting_value: '4',
        description: 'Maximum images per product (1 poster + 3 additional)',
        updated_at: new Date(),
      },
      {
        setting_key: 'image_max_size_kb',
        setting_value: '2048',
        description: 'Maximum image size in KB',
        updated_at: new Date(),
      },
      {
        setting_key: 'default_search_radius_km',
        setting_value: '50',
        description: 'Default search radius in kilometers',
        updated_at: new Date(),
      },
      {
        setting_key: 'min_password_length',
        setting_value: '8',
        description: 'Minimum password length',
        updated_at: new Date(),
      },
      {
        setting_key: 'max_cart_items',
        setting_value: '50',
        description: 'Maximum items allowed in inquiry cart',
        updated_at: new Date(),
      },
      {
        setting_key: 'project_approval_required',
        setting_value: 'true',
        description: 'Whether new projects require admin approval',
        updated_at: new Date(),
      },
      {
        setting_key: 'product_approval_required',
        setting_value: 'true',
        description: 'Whether new products require admin approval',
        updated_at: new Date(),
      },
      {
        setting_key: 'review_approval_required',
        setting_value: 'true',
        description: 'Whether new reviews require admin approval',
        updated_at: new Date(),
      },
      {
        setting_key: 'app_version_ios',
        setting_value: '1.0.0',
        description: 'Current iOS app version',
        updated_at: new Date(),
      },
      {
        setting_key: 'app_version_android',
        setting_value: '1.0.0',
        description: 'Current Android app version',
        updated_at: new Date(),
      },
      {
        setting_key: 'maintenance_mode',
        setting_value: 'false',
        description: 'Whether the app is in maintenance mode',
        updated_at: new Date(),
      },
    ]);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('system_settings', null, {});
  },
};

