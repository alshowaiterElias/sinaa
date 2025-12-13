'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // We use raw query to modify the ENUM column as it's the most reliable way across different SQL dialects
        // for adding a value to an ENUM without losing data.
        // This syntax is for MySQL/MariaDB which is likely being used given the error message.
        await queryInterface.sequelize.query(
            "ALTER TABLE `projects` MODIFY COLUMN `status` ENUM('pending', 'approved', 'rejected', 'disabled') NOT NULL DEFAULT 'pending';"
        );
    },

    async down(queryInterface, Sequelize) {
        // Revert changes - note that if there are any 'disabled' projects, this might fail or truncate data
        // We'll set them to 'rejected' first to be safe before reverting
        await queryInterface.sequelize.query(
            "UPDATE `projects` SET `status` = 'rejected' WHERE `status` = 'disabled';"
        );

        await queryInterface.sequelize.query(
            "ALTER TABLE `projects` MODIFY COLUMN `status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending';"
        );
    }
};
