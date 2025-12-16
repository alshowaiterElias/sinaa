import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Project from './Project';

// Conversation attributes interface
export interface ConversationAttributes {
    id: number;
    user1Id: number;      // Normalized: always the smaller user ID
    user2Id: number;      // Normalized: always the larger user ID
    projectId: number | null;   // Optional: context for product-related chats
    lastMessageAt: Date | null;
    createdAt: Date;
}

// Attributes for creation
export interface ConversationCreationAttributes
    extends Optional<ConversationAttributes, 'id' | 'projectId' | 'lastMessageAt' | 'createdAt'> { }

// Conversation model class
class Conversation
    extends Model<ConversationAttributes, ConversationCreationAttributes>
    implements ConversationAttributes {
    public id!: number;
    public user1Id!: number;
    public user2Id!: number;
    public projectId!: number | null;
    public lastMessageAt!: Date | null;
    public createdAt!: Date;

    // Associations
    public readonly user1?: User;
    public readonly user2?: User;
    public readonly project?: Project;

    // Helper method to check if a user is part of this conversation
    public hasParticipant(userId: number): boolean {
        return this.user1Id === userId || this.user2Id === userId;
    }

    // Helper method to get the other participant
    public getOtherParticipantId(userId: number): number | null {
        if (this.user1Id === userId) return this.user2Id;
        if (this.user2Id === userId) return this.user1Id;
        return null;
    }
}

Conversation.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        user1Id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'user1_id',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        user2Id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'user2_id',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        projectId: {
            type: DataTypes.INTEGER,
            allowNull: true,
            field: 'project_id',
            references: {
                model: 'projects',
                key: 'id',
            },
        },
        lastMessageAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'last_message_at',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        tableName: 'conversations',
        timestamps: false,
        underscored: true,
    }
);

// Associations
Conversation.belongsTo(User, { foreignKey: 'user1Id', as: 'user1' });
Conversation.belongsTo(User, { foreignKey: 'user2Id', as: 'user2' });
Conversation.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

export default Conversation;


