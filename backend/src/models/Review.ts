import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Product from './Product';
import Transaction from './Transaction';

// Review status types
export type ReviewStatus = 'pending' | 'approved' | 'rejected';

// Review attributes interface
export interface ReviewAttributes {
    id: number;
    productId: number;
    userId: number;
    transactionId: number;
    rating: number;
    comment: string | null;
    ownerReply: string | null;
    ownerReplyAt: Date | null;
    status: ReviewStatus;
    createdAt: Date;
    updatedAt: Date | null;
}

// Attributes for creation
export interface ReviewCreationAttributes
    extends Optional<ReviewAttributes, 'id' | 'comment' | 'ownerReply' | 'ownerReplyAt' | 'status' | 'createdAt' | 'updatedAt'> { }

// Review model class
class Review
    extends Model<ReviewAttributes, ReviewCreationAttributes>
    implements ReviewAttributes {
    public id!: number;
    public productId!: number;
    public userId!: number;
    public transactionId!: number;
    public rating!: number;
    public comment!: string | null;
    public ownerReply!: string | null;
    public ownerReplyAt!: Date | null;
    public status!: ReviewStatus;
    public readonly createdAt!: Date;
    public updatedAt!: Date | null;

    // Associations
    public readonly user?: User;
    public readonly product?: Product;
    public readonly transaction?: Transaction;

    // Check if review is approved
    public isApproved(): boolean {
        return this.status === 'approved';
    }

    // Check if review is pending
    public isPending(): boolean {
        return this.status === 'pending';
    }
}

Review.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        productId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'product_id',
            references: {
                model: 'products',
                key: 'id',
            },
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
        transactionId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'transaction_id',
            references: {
                model: 'transactions',
                key: 'id',
            },
        },
        rating: {
            type: DataTypes.TINYINT,
            allowNull: false,
            validate: {
                min: 1,
                max: 5,
            },
        },
        comment: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        ownerReply: {
            type: DataTypes.TEXT,
            allowNull: true,
            field: 'owner_reply',
        },
        ownerReplyAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'owner_reply_at',
        },
        status: {
            type: DataTypes.ENUM('pending', 'approved', 'rejected'),
            defaultValue: 'approved',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
            defaultValue: DataTypes.NOW,
        },
        updatedAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'updated_at',
        },
    },
    {
        sequelize,
        tableName: 'reviews',
        timestamps: false,
        underscored: true,
        indexes: [
            { fields: ['product_id'] },
            { fields: ['user_id'] },
            { fields: ['transaction_id'] },
            { fields: ['status'] },
            { fields: ['rating'] },
        ],
    }
);

// Associations
Review.belongsTo(User, { foreignKey: 'userId', as: 'user' });
Review.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
Review.belongsTo(Transaction, { foreignKey: 'transactionId', as: 'transaction' });

export default Review;
