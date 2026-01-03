import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

// Category attributes interface
export interface CategoryAttributes {
  id: number;
  parentId: number | null;
  name: string;
  nameAr: string;
  icon: string | null;
  sortOrder: number;
  isActive: boolean;
  status: 'active' | 'inactive' | 'pending' | 'rejected';
  createdBy: number | null;
  rejectionReason: string | null;
  createdAt: Date;
}

// Attributes for creation
export interface CategoryCreationAttributes
  extends Optional<
    CategoryAttributes,
    'id' | 'parentId' | 'icon' | 'sortOrder' | 'isActive' | 'status' | 'createdBy' | 'rejectionReason' | 'createdAt'
  > { }

// Category model class
class Category
  extends Model<CategoryAttributes, CategoryCreationAttributes>
  implements CategoryAttributes {
  public id!: number;
  public parentId!: number | null;
  public name!: string;
  public nameAr!: string;
  public icon!: string | null;
  public sortOrder!: number;
  public isActive!: boolean;
  public status!: 'active' | 'inactive' | 'pending' | 'rejected';
  public createdBy!: number | null;
  public rejectionReason!: string | null;
  public createdAt!: Date;

  // Virtual associations
  public readonly parent?: Category;
  public readonly children?: Category[];
  public readonly productCount?: number;

  // Helper methods
  public isParentCategory(): boolean {
    return this.parentId === null;
  }

  public isSubcategory(): boolean {
    return this.parentId !== null;
  }

  // Get localized name based on language
  public getLocalizedName(language: 'ar' | 'en' = 'ar'): string {
    return language === 'ar' ? this.nameAr : this.name;
  }

  // Format for API response
  public toJSON(): CategoryAttributes & { children?: Category[] } {
    const values = super.toJSON() as CategoryAttributes & { children?: Category[] };
    return values;
  }
}

Category.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    parentId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'parent_id',
      references: {
        model: 'categories',
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
    icon: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    sortOrder: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'sort_order',
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'is_active',
    },
    status: {
      type: DataTypes.ENUM('active', 'inactive', 'pending', 'rejected'),
      defaultValue: 'active',
      allowNull: false,
    },
    createdBy: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'created_by',
      references: {
        model: 'users',
        key: 'id',
      },
    },
    rejectionReason: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: 'rejection_reason',
    },
    createdAt: {
      type: DataTypes.DATE,
      field: 'created_at',
    },
  },
  {
    sequelize,
    tableName: 'categories',
    timestamps: false, // Only createdAt, no updatedAt
    underscored: true,
    indexes: [
      { fields: ['parent_id'] },
      { fields: ['is_active'] },
      { fields: ['sort_order'] },
      { fields: ['status'] },
    ],
  }
);

// Self-referencing associations for parent-child relationship
Category.belongsTo(Category, {
  as: 'parent',
  foreignKey: 'parentId',
});

Category.hasMany(Category, {
  as: 'children',
  foreignKey: 'parentId',
});

import User from './User';
Category.belongsTo(User, {
  as: 'creator',
  foreignKey: 'createdBy',
});

export default Category;

