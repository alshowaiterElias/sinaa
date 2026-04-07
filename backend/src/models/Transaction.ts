import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Conversation from './Conversation';
import Product from './Product';

// Transaction status types
export type TransactionStatus = 'pending' | 'preparing' | 'ready_to_deliver' | 'delivered' | 'disputed' | 'cancelled';

// Transaction attributes interface
export interface TransactionAttributes {
    id: number;
    conversationId: number;
    productId: number | null;
    initiatedBy: number;
    status: TransactionStatus;
    preparingAt: Date | null;
    readyToDeliverAt: Date | null;
    deliveredAt: Date | null;
    createdAt: Date;
}

// Attributes for creation
export interface TransactionCreationAttributes
    extends Optional<TransactionAttributes, 'id' | 'productId' | 'status' | 'preparingAt' | 'readyToDeliverAt' | 'deliveredAt' | 'createdAt'> { }

// Transaction model class
class Transaction
    extends Model<TransactionAttributes, TransactionCreationAttributes>
    implements TransactionAttributes {
    public id!: number;
    public conversationId!: number;
    public productId!: number | null;
    public initiatedBy!: number;
    public status!: TransactionStatus;
    public preparingAt!: Date | null;
    public readyToDeliverAt!: Date | null;
    public deliveredAt!: Date | null;
    public readonly createdAt!: Date;

    // Associations
    public readonly initiator?: User;
    public readonly conversation?: Conversation;
    public readonly product?: Product;

    // Check statuses
    public isPending(): boolean {
        return this.status === 'pending';
    }

    public isPreparing(): boolean {
        return this.status === 'preparing';
    }

    public isReadyToDeliver(): boolean {
        return this.status === 'ready_to_deliver';
    }

    public isDelivered(): boolean {
        return this.status === 'delivered';
    }
}

Transaction.init(
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
        productId: {
            type: DataTypes.INTEGER,
            allowNull: true,
            field: 'product_id',
            references: {
                model: 'products',
                key: 'id',
            },
        },
        initiatedBy: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'initiated_by',
            references: {
                model: 'users',
                key: 'id',
            },
        },
        preparingAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'preparing_at',
        },
        readyToDeliverAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'ready_to_deliver_at',
        },
        deliveredAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'delivered_at',
        },
        status: {
            type: DataTypes.ENUM('pending', 'preparing', 'ready_to_deliver', 'delivered', 'disputed', 'cancelled'),
            defaultValue: 'pending',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        tableName: 'transactions',
        timestamps: false,
        underscored: true,
        indexes: [
            { fields: ['conversation_id'] },
            { fields: ['product_id'] },
            { fields: ['initiated_by'] },
            { fields: ['status'] },
        ],
    }
);

// Associations
Transaction.belongsTo(User, { foreignKey: 'initiatedBy', as: 'initiator' });
Transaction.belongsTo(Conversation, { foreignKey: 'conversationId', as: 'conversation' });
Transaction.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

export default Transaction;
