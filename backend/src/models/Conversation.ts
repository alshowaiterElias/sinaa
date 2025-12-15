import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Project from './Project';

// Conversation attributes interface
export interface ConversationAttributes {
    id: number;
    customerId: number;
    projectId: number;
    lastMessageAt: Date | null;
    createdAt: Date;
}

// Attributes for creation
export interface ConversationCreationAttributes
    extends Optional<ConversationAttributes, 'id' | 'lastMessageAt' | 'createdAt'> { }

// Conversation model class
class Conversation
    extends Model<ConversationAttributes, ConversationCreationAttributes>
    implements ConversationAttributes {
    public id!: number;
    public customerId!: number;
    public projectId!: number;
    public lastMessageAt!: Date | null;
    public createdAt!: Date;

    // Associations
    public readonly customer?: User;
    public readonly project?: Project;
}

Conversation.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        customerId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'customer_id',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        projectId: {
            type: DataTypes.INTEGER,
            allowNull: false,
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
Conversation.belongsTo(User, { foreignKey: 'customerId', as: 'customer' });
Conversation.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

export default Conversation;
