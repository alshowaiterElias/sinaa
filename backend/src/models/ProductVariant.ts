import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import Product from './Product';

export interface ProductVariantAttributes {
    id: number;
    productId: number;
    name: string;
    nameAr: string;
    priceModifier: number;
    quantity: number;
    isAvailable: boolean;
    createdAt: Date;
}

export interface ProductVariantCreationAttributes
    extends Optional<
        ProductVariantAttributes,
        'id' | 'priceModifier' | 'quantity' | 'isAvailable' | 'createdAt'
    > { }

class ProductVariant
    extends Model<ProductVariantAttributes, ProductVariantCreationAttributes>
    implements ProductVariantAttributes {
    public id!: number;
    public productId!: number;
    public name!: string;
    public nameAr!: string;
    public priceModifier!: number;
    public quantity!: number;
    public isAvailable!: boolean;
    public createdAt!: Date;

    // Associations
    public readonly product?: Product;
}

ProductVariant.init(
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
        name: {
            type: DataTypes.STRING(100),
            allowNull: false,
        },
        nameAr: {
            type: DataTypes.STRING(100),
            allowNull: false,
            field: 'name_ar',
        },
        priceModifier: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0,
            field: 'price_modifier',
        },
        quantity: {
            type: DataTypes.INTEGER,
            defaultValue: 0,
        },
        isAvailable: {
            type: DataTypes.BOOLEAN,
            defaultValue: true,
            field: 'is_available',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
        },
    },
    {
        sequelize,
        tableName: 'product_variants',
        timestamps: false, // Only created_at exists
        underscored: true,
        indexes: [
            { fields: ['product_id'] },
            { fields: ['is_available'] },
        ],
    }
);

export default ProductVariant;
