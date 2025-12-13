import sequelize from '../src/config/database';

async function run() {
    try {
        console.log('Connecting to database...');
        await sequelize.authenticate();
        console.log('Connection established successfully.');

        console.log('Updating project status enum...');
        await sequelize.query(
            "ALTER TABLE `projects` MODIFY COLUMN `status` ENUM('pending', 'approved', 'rejected', 'disabled') NOT NULL DEFAULT 'pending';"
        );
        console.log('Enum updated successfully.');

        process.exit(0);
    } catch (error) {
        console.error('Unable to update enum:', error);
        process.exit(1);
    }
}

run();
