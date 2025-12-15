import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import Product from './Product';

export interface TagAttributes {
    id: number;
    name: string;
    nameAr: string;
    createdAt: Date;
}

export interface TagCreationAttributes
    extends Optional<TagAttributes, 'id' | 'createdAt'> { }

class Tag
    extends Model<TagAttributes, TagCreationAttributes>
    implements TagAttributes {
    public id!: number;
    public name!: string;
    public nameAr!: string;
    public createdAt!: Date;

    // Associations
    public readonly products?: Product[];
}

Tag.init(
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        name: {
            type: DataTypes.STRING(50),
            allowNull: false,
        },
        nameAr: {
            type: DataTypes.STRING(50),
            allowNull: false,
            field: 'name_ar',
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
        },
    },
    {
        sequelize,
        tableName: 'tags',
        timestamps: false, // Only created_at exists
        underscored: true,
    }
);

export default Tag;
