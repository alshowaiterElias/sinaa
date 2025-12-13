import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';

dotenv.config();

const env = process.env.NODE_ENV || 'development';

// Create sequelize instance based on environment
const createSequelizeInstance = (): Sequelize => {
  // Use SQLite in-memory for tests
  if (env === 'test') {
    return new Sequelize({
      dialect: 'sqlite',
      storage: ':memory:',
      logging: false,
      define: {
        timestamps: true,
        underscored: true,
      },
    });
  }

  // MySQL for development and production
  const config = {
    development: {
      username: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'sinaa_dev',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      dialect: 'mysql' as const,
      logging: console.log,
    },
    production: {
      username: process.env.DB_USER!,
      password: process.env.DB_PASSWORD!,
      database: process.env.DB_NAME!,
      host: process.env.DB_HOST!,
      port: parseInt(process.env.DB_PORT || '3306'),
      dialect: 'mysql' as const,
      logging: false,
      pool: {
        max: 10,
        min: 2,
        acquire: 30000,
        idle: 10000,
      },
    },
  };

  const dbConfig = config[env as keyof typeof config] || config.development;

  return new Sequelize(
    dbConfig.database,
    dbConfig.username,
    dbConfig.password,
    {
      host: dbConfig.host,
      port: dbConfig.port,
      dialect: dbConfig.dialect,
      logging: dbConfig.logging,
      define: {
        timestamps: true,
        underscored: true,
      },
      ...(env === 'production' && { pool: config.production.pool }),
    }
  );
};

export const sequelize = createSequelizeInstance();

export const connectDatabase = async (): Promise<void> => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');
  } catch (error) {
    console.error('❌ Unable to connect to the database:', error);
    process.exit(1);
  }
};

export default sequelize;
