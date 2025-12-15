import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import Conversation from './Conversation';
import User from './User';

export type MessageType = 'text' | 'inquiry' | 'image' | 'transaction';

// Message attributes interface
export interface MessageAttributes {
    id: number;
    conversationId: number;
    senderId: number;
    content: string;
    messageType: MessageType;
    isRead: boolean;
    createdAt: Date;
}

// Attributes for creation
export interface MessageCreationAttributes
    extends Optional<MessageAttributes, 'id' | 'messageType' | 'isRead' | 'createdAt'> { }

// Message model class
class Message
    extends Model<MessageAttributes, MessageCreationAttributes>
    implements MessageAttributes {
    public id!: number;
    public conversationId!: number;
    public senderId!: number;
    public content!: string;
    public messageType!: MessageType;
    public isRead!: boolean;
    public createdAt!: Date;

    // Associations
    public readonly conversation?: Conversation;
    public readonly sender?: User;
}

Message.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        conversationId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'conversation_id',
            references: {
                model: 'conversations',
                key: 'id',
            },
        },
        senderId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'sender_id',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        content: {
            type: DataTypes.TEXT,
            allowNull: false,
        },
        messageType: {
            type: DataTypes.ENUM('text', 'inquiry', 'image', 'transaction'),
            defaultValue: 'text',
            field: 'message_type',
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
        tableName: 'messages',
        timestamps: false,
        underscored: true,
    }
);

// Associations
Message.belongsTo(Conversation, { foreignKey: 'conversationId', as: 'conversation' });
Message.belongsTo(User, { foreignKey: 'senderId', as: 'sender' });

export default Message;
