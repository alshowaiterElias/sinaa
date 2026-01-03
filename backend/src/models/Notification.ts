import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';

export type NotificationType =
    | 'message'
    | 'transaction'
    | 'transaction_initiated'
    | 'transaction_confirmed'
    | 'transaction_denied'
    | 'transaction_disputed'
    | 'transaction_cancelled'
    | 'transaction_auto_confirmed'
    | 'review'
    | 'new_review'
    | 'review_approved'
    | 'review_rejected'
    | 'project_approval'
    | 'product_approval'
    | 'inquiry';

// Notification data structure
export interface NotificationData {
    conversationId?: number;
    projectId?: number;
    productId?: number;
    transactionId?: number;
    reviewId?: number;
    messageId?: number;
    senderId?: number;
    senderName?: string;
    autoConfirmAt?: Date;
    rating?: number;
    ticketId?: number;
    [key: string]: unknown;
}

// Notification attributes interface
export interface NotificationAttributes {
    id: number;
    userId: number;
    type: NotificationType;
    title: string;
    titleAr: string;
    body: string | null;
    bodyAr: string | null;
    data: NotificationData | null;
    isRead: boolean;
    createdAt: Date;
}

// Attributes for creation
export interface NotificationCreationAttributes
    extends Optional<NotificationAttributes, 'id' | 'body' | 'bodyAr' | 'data' | 'isRead' | 'createdAt'> { }

// Notification model class
class Notification
    extends Model<NotificationAttributes, NotificationCreationAttributes>
    implements NotificationAttributes {
    public id!: number;
    public userId!: number;
    public type!: NotificationType;
    public title!: string;
    public titleAr!: string;
    public body!: string | null;
    public bodyAr!: string | null;
    public data!: NotificationData | null;
    public isRead!: boolean;
    public createdAt!: Date;

    // Associations
    public readonly user?: User;

    // Get localized title
    public getLocalizedTitle(locale: string): string {
        return locale === 'ar' ? this.titleAr : this.title;
    }

    // Get localized body
    public getLocalizedBody(locale: string): string | null {
        return locale === 'ar' ? this.bodyAr : this.body;
    }
}

Notification.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        userId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'user_id',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        type: {
            type: DataTypes.STRING(50),
            allowNull: false,
        },
        title: {
            type: DataTypes.STRING(200),
            allowNull: false,
        },
        titleAr: {
            type: DataTypes.STRING(200),
            allowNull: false,
            field: 'title_ar',
        },
        body: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        bodyAr: {
            type: DataTypes.TEXT,
            allowNull: true,
            field: 'body_ar',
        },
        data: {
            type: DataTypes.JSON,
            allowNull: true,
        },
        isRead: {
            type: DataTypes.BOOLEAN,
            defaultValue: false,
            field: 'is_read',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        tableName: 'notifications',
        timestamps: false,
        underscored: true,
        indexes: [
            { fields: ['user_id'] },
            { fields: ['type'] },
            { fields: ['is_read'] },
            { fields: ['created_at'] },
        ],
    }
);

// Associations
Notification.belongsTo(User, { foreignKey: 'userId', as: 'user' });

export default Notification;
