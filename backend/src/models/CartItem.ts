import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Product from './Product';
import ProductVariant from './ProductVariant';

// CartItem attributes interface
export interface CartItemAttributes {
    id: number;
    userId: number;
    productId: number;
    variantId: number | null;
    quantity: number;
    note: string | null;
    createdAt: Date;
}

// Attributes for creation
export interface CartItemCreationAttributes
    extends Optional<CartItemAttributes, 'id' | 'variantId' | 'quantity' | 'note' | 'createdAt'> { }

// CartItem model class
class CartItem
    extends Model<CartItemAttributes, CartItemCreationAttributes>
    implements CartItemAttributes {
    public id!: number;
    public userId!: number;
    public productId!: number;
    public variantId!: number | null;
    public quantity!: number;
    public note!: string | null;
    public createdAt!: Date;

    // Associations
    public readonly user?: User;
    public readonly product?: Product;
    public readonly variant?: ProductVariant;
}

CartItem.init(
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
        productId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'product_id',
            references: {
                model: 'products',
                key: 'id',
            },
        },
        variantId: {
            type: DataTypes.INTEGER,
            allowNull: true,
            field: 'variant_id',
            references: {
                model: 'product_variants',
                key: 'id',
            },
        },
        quantity: {
            type: DataTypes.INTEGER,
            defaultValue: 1,
        },
        note: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        tableName: 'cart_items',
        timestamps: false,
        underscored: true,
    }
);

// Associations
CartItem.belongsTo(User, { foreignKey: 'userId', as: 'user' });
CartItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
CartItem.belongsTo(ProductVariant, { foreignKey: 'variantId', as: 'variant' });

export default CartItem;
