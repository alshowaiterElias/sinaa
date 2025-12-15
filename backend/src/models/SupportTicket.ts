import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';

// Ticket types
export type TicketType = 'general' | 'dispute' | 'report' | 'feedback';

// Ticket status
export type TicketStatus = 'open' | 'in_progress' | 'resolved' | 'closed';

// Related entity types
export type RelatedType = 'transaction' | 'product' | 'project' | 'user' | null;

// SupportTicket attributes interface
export interface SupportTicketAttributes {
    id: number;
    userId: number;
    type: TicketType;
    subject: string;
    description: string;
    relatedId: number | null;
    relatedType: RelatedType;
    status: TicketStatus;
    assignedTo: number | null;
    resolution: string | null;
    createdAt: Date;
    updatedAt: Date;
}

// Attributes for creation
export interface SupportTicketCreationAttributes
    extends Optional<SupportTicketAttributes, 'id' | 'relatedId' | 'relatedType' | 'status' | 'assignedTo' | 'resolution' | 'createdAt' | 'updatedAt'> { }

// SupportTicket model class
class SupportTicket
    extends Model<SupportTicketAttributes, SupportTicketCreationAttributes>
    implements SupportTicketAttributes {
    public id!: number;
    public userId!: number;
    public type!: TicketType;
    public subject!: string;
    public description!: string;
    public relatedId!: number | null;
    public relatedType!: RelatedType;
    public status!: TicketStatus;
    public assignedTo!: number | null;
    public resolution!: string | null;
    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;

    // Associations
    public readonly user?: User;
    public readonly assignee?: User;

    // Check if ticket is open
    public isOpen(): boolean {
        return this.status === 'open' || this.status === 'in_progress';
    }

    // Check if ticket is closed
    public isClosed(): boolean {
        return this.status === 'resolved' || this.status === 'closed';
    }
}

SupportTicket.init(
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
            type: DataTypes.ENUM('general', 'dispute', 'report', 'feedback'),
            allowNull: false,
        },
        subject: {
            type: DataTypes.STRING(200),
            allowNull: false,
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: false,
        },
        relatedId: {
            type: DataTypes.INTEGER,
            allowNull: true,
            field: 'related_id',
        },
        relatedType: {
            type: DataTypes.STRING(50),
            allowNull: true,
            field: 'related_type',
        },
        status: {
            type: DataTypes.ENUM('open', 'in_progress', 'resolved', 'closed'),
            defaultValue: 'open',
        },
        assignedTo: {
            type: DataTypes.INTEGER,
            allowNull: true,
            field: 'assigned_to',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        resolution: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
            defaultValue: DataTypes.NOW,
        },
        updatedAt: {
            type: DataTypes.DATE,
            field: 'updated_at',
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        tableName: 'support_tickets',
        timestamps: true,
        underscored: true,
        indexes: [
            { fields: ['user_id'] },
            { fields: ['type'] },
            { fields: ['status'] },
            { fields: ['assigned_to'] },
            { fields: ['created_at'] },
        ],
    }
);

// Associations
SupportTicket.belongsTo(User, { foreignKey: 'userId', as: 'user' });
SupportTicket.belongsTo(User, { foreignKey: 'assignedTo', as: 'assignee' });

export default SupportTicket;
