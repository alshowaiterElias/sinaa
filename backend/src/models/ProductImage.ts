import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import Product from './Product';

export interface ProductImageAttributes {
    id: number;
    productId: number;
    imageUrl: string;
    sortOrder: number;
    createdAt: Date;
}

export interface ProductImageCreationAttributes
    extends Optional<ProductImageAttributes, 'id' | 'sortOrder' | 'createdAt'> { }

class ProductImage
    extends Model<ProductImageAttributes, ProductImageCreationAttributes>
    implements ProductImageAttributes {
    public id!: number;
    public productId!: number;
    public imageUrl!: string;
    public sortOrder!: number;
    public createdAt!: Date;

    // Associations
    public readonly product?: Product;
}

ProductImage.init(
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
        imageUrl: {
            type: DataTypes.STRING(500),
            allowNull: false,
            field: 'image_url',
        },
        sortOrder: {
            type: DataTypes.INTEGER,
            defaultValue: 0,
            field: 'sort_order',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
        },
    },
    {
        sequelize,
        tableName: 'product_images',
        timestamps: false, // Only created_at exists
        underscored: true,
        indexes: [
            { fields: ['product_id'] },
        ],
    }
);

export default ProductImage;
