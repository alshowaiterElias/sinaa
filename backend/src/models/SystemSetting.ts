import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

// SystemSetting attributes interface
export interface SystemSettingAttributes {
    id: number;
    settingKey: string;
    settingValue: string;
    description: string | null;
    updatedAt: Date;
}

// Attributes for creation
export interface SystemSettingCreationAttributes
    extends Optional<SystemSettingAttributes, 'id' | 'description' | 'updatedAt'> { }

// Default system settings
export const DEFAULT_SETTINGS = {
    TRANSACTION_AUTO_CONFIRM_DAYS: '7', // 1 week
    REVIEW_AUTO_APPROVE: 'false',
    MAX_RATING: '5',
    MIN_RATING: '1',
} as const;

// SystemSetting model class
class SystemSetting
    extends Model<SystemSettingAttributes, SystemSettingCreationAttributes>
    implements SystemSettingAttributes {
    public id!: number;
    public settingKey!: string;
    public settingValue!: string;
    public description!: string | null;
    public readonly updatedAt!: Date;

    // Static method to get a setting value
    public static async getSetting(key: string): Promise<string | null> {
        const setting = await SystemSetting.findOne({
            where: { settingKey: key },
        });
        return setting?.settingValue ?? null;
    }

    // Static method to get a setting as number
    public static async getSettingAsNumber(key: string, defaultValue: number): Promise<number> {
        const value = await SystemSetting.getSetting(key);
        if (value === null) return defaultValue;
        const parsed = parseInt(value, 10);
        return isNaN(parsed) ? defaultValue : parsed;
    }

    // Static method to get a setting as boolean
    public static async getSettingAsBoolean(key: string, defaultValue: boolean): Promise<boolean> {
        const value = await SystemSetting.getSetting(key);
        if (value === null) return defaultValue;
        return value.toLowerCase() === 'true';
    }

    // Static method to set a setting value
    public static async setSetting(key: string, value: string, description?: string): Promise<SystemSetting> {
        const [setting] = await SystemSetting.upsert({
            settingKey: key,
            settingValue: value,
            description: description ?? null,
        });
        return setting;
    }

    // Get auto-confirm days setting
    public static async getAutoConfirmDays(): Promise<number> {
        return SystemSetting.getSettingAsNumber('TRANSACTION_AUTO_CONFIRM_DAYS', 7);
    }
}

SystemSetting.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        settingKey: {
            type: DataTypes.STRING(100),
            allowNull: false,
            unique: true,
            field: 'setting_key',
        },
        settingValue: {
            type: DataTypes.TEXT,
            allowNull: false,
            field: 'setting_value',
        },
        description: {
            type: DataTypes.STRING(255),
            allowNull: true,
        },
        updatedAt: {
            type: DataTypes.DATE,
            field: 'updated_at',
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        tableName: 'system_settings',
        timestamps: true,
        updatedAt: 'updated_at',
        createdAt: false,
        underscored: true,
        indexes: [
            { fields: ['setting_key'], unique: true },
        ],
    }
);

export default SystemSetting;
