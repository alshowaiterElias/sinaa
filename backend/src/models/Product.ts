import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import { PROJECT_STATUS } from '../config/constants';
import Project from './Project';
import Category from './Category';

type ProductStatus = 'pending' | 'approved' | 'rejected';

// Product attributes interface
export interface ProductAttributes {
    id: number;
    projectId: number;
    categoryId: number;
    name: string;
    nameAr: string;
    description: string | null;
    descriptionAr: string | null;
    basePrice: number;
    posterImageUrl: string;
    quantity: number;
    isAvailable: boolean;
    status: ProductStatus;
    rejectionReason: string | null;
    averageRating: number;
    totalReviews: number;
    viewCount: number;
    createdAt: Date;
    updatedAt: Date;
}

// Attributes for creation
export interface ProductCreationAttributes
    extends Optional<
        ProductAttributes,
        | 'id'
        | 'description'
        | 'descriptionAr'
        | 'quantity'
        | 'isAvailable'
        | 'status'
        | 'rejectionReason'
        | 'averageRating'
        | 'totalReviews'
        | 'viewCount'
        | 'createdAt'
        | 'updatedAt'
    > { }

// Product model class
class Product
    extends Model<ProductAttributes, ProductCreationAttributes>
    implements ProductAttributes {
    public id!: number;
    public projectId!: number;
    public categoryId!: number;
    public name!: string;
    public nameAr!: string;
    public description!: string | null;
    public descriptionAr!: string | null;
    public basePrice!: number;
    public posterImageUrl!: string;
    public quantity!: number;
    public isAvailable!: boolean;
    public status!: ProductStatus;
    public rejectionReason!: string | null;
    public averageRating!: number;
    public totalReviews!: number;
    public viewCount!: number;
    public createdAt!: Date;
    public updatedAt!: Date;

    // Associations
    public readonly project?: Project;
    public readonly category?: Category;

    // Helper methods
    public isApproved(): boolean {
        return this.status === PROJECT_STATUS.APPROVED;
    }
}

Product.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
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
        categoryId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'category_id',
            references: {
                model: 'categories',
                key: 'id',
            },
        },
        name: {
            type: DataTypes.STRING(200),
            allowNull: false,
        },
        nameAr: {
            type: DataTypes.STRING(200),
            allowNull: false,
            field: 'name_ar',
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        descriptionAr: {
            type: DataTypes.TEXT,
            allowNull: true,
            field: 'description_ar',
        },
        basePrice: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false,
            field: 'base_price',
        },
        posterImageUrl: {
            type: DataTypes.STRING(500),
            allowNull: false,
            field: 'poster_image_url',
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
        status: {
            type: DataTypes.ENUM('pending', 'approved', 'rejected'),
            defaultValue: 'pending',
        },
        rejectionReason: {
            type: DataTypes.TEXT,
            allowNull: true,
            field: 'rejection_reason',
        },
        averageRating: {
            type: DataTypes.DECIMAL(2, 1),
            defaultValue: 0,
            field: 'average_rating',
        },
        totalReviews: {
            type: DataTypes.INTEGER,
            defaultValue: 0,
            field: 'total_reviews',
        },
        viewCount: {
            type: DataTypes.INTEGER,
            defaultValue: 0,
            field: 'view_count',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
        },
        updatedAt: {
            type: DataTypes.DATE,
            field: 'updated_at',
        },
    },
    {
        sequelize,
        tableName: 'products',
        timestamps: true,
        underscored: true,
        indexes: [
            { fields: ['project_id'] },
            { fields: ['category_id'] },
            { fields: ['status'] },
            { fields: ['is_available'] },
            { fields: ['average_rating'] },
        ],
    }
);

// Define associations
Project.hasMany(Product, { foreignKey: 'projectId', as: 'products' });
Product.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

Category.hasMany(Product, { foreignKey: 'categoryId', as: 'products' });
Product.belongsTo(Category, { foreignKey: 'categoryId', as: 'category' });

export default Product;
