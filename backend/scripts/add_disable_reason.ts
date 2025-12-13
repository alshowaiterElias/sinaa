import sequelize from '../src/config/database';

async function run() {
    try {
        console.log('Connecting to database...');
        await sequelize.authenticate();
        console.log('Connection established successfully.');

        console.log('Adding disable_reason column...');
        await sequelize.query(
            "ALTER TABLE `projects` ADD COLUMN `disable_reason` TEXT NULL AFTER `status`;"
        );
        console.log('Column added successfully.');

        process.exit(0);
    } catch (error) {
        console.error('Unable to add column:', error);
        process.exit(1);
    }
}

run();
