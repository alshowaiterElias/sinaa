import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Conversation from './Conversation';
import Product from './Product';

// Transaction status types
export type TransactionStatus = 'pending' | 'confirmed' | 'disputed' | 'cancelled';

// Transaction attributes interface
export interface TransactionAttributes {
    id: number;
    conversationId: number;
    productId: number | null;
    initiatedBy: number;
    customerConfirmed: boolean;
    sellerConfirmed: boolean;
    customerConfirmedAt: Date | null;
    sellerConfirmedAt: Date | null;
    status: TransactionStatus;
    autoConfirmAt: Date;
    createdAt: Date;
}

// Attributes for creation
export interface TransactionCreationAttributes
    extends Optional<TransactionAttributes, 'id' | 'productId' | 'customerConfirmed' | 'sellerConfirmed' | 'customerConfirmedAt' | 'sellerConfirmedAt' | 'status' | 'createdAt'> { }

// Transaction model class
class Transaction
    extends Model<TransactionAttributes, TransactionCreationAttributes>
    implements TransactionAttributes {
    public id!: number;
    public conversationId!: number;
    public productId!: number | null;
    public initiatedBy!: number;
    public customerConfirmed!: boolean;
    public sellerConfirmed!: boolean;
    public customerConfirmedAt!: Date | null;
    public sellerConfirmedAt!: Date | null;
    public status!: TransactionStatus;
    public autoConfirmAt!: Date;
    public readonly createdAt!: Date;

    // Associations
    public readonly initiator?: User;
    public readonly conversation?: Conversation;
    public readonly product?: Product;

    // Check if transaction is pending
    public isPending(): boolean {
        return this.status === 'pending';
    }

    // Check if transaction is confirmed
    public isConfirmed(): boolean {
        return this.status === 'confirmed';
    }

    // Check if both parties have confirmed
    public isFullyConfirmed(): boolean {
        return this.customerConfirmed && this.sellerConfirmed;
    }

    // Check if auto-confirm time has passed
    public shouldAutoConfirm(): boolean {
        return this.status === 'pending' && new Date() >= this.autoConfirmAt;
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
        customerConfirmed: {
            type: DataTypes.BOOLEAN,
            defaultValue: false,
            field: 'customer_confirmed',
        },
        sellerConfirmed: {
            type: DataTypes.BOOLEAN,
            defaultValue: false,
            field: 'seller_confirmed',
        },
        customerConfirmedAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'customer_confirmed_at',
        },
        sellerConfirmedAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'seller_confirmed_at',
        },
        status: {
            type: DataTypes.ENUM('pending', 'confirmed', 'disputed', 'cancelled'),
            defaultValue: 'pending',
        },
        autoConfirmAt: {
            type: DataTypes.DATE,
            allowNull: false,
            field: 'auto_confirm_at',
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
            { fields: ['auto_confirm_at'] },
        ],
    }
);

// Associations
Transaction.belongsTo(User, { foreignKey: 'initiatedBy', as: 'initiator' });
Transaction.belongsTo(Conversation, { foreignKey: 'conversationId', as: 'conversation' });
Transaction.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

export default Transaction;
