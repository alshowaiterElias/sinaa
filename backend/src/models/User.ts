import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import { UserRole, USER_ROLES, LANGUAGES } from '../config/constants';

// User attributes interface
export interface UserAttributes {
  id: number;
  email: string;
  passwordHash: string;
  phone: string | null;
  fullName: string;
  avatarUrl: string | null;
  role: UserRole;
  language: 'ar' | 'en';
  isActive: boolean;
  isBanned: boolean;
  banReason: string | null;
  refreshToken: string | null;
  createdAt: Date;
  updatedAt: Date;
}

// Attributes for creation (id, timestamps are optional)
export interface UserCreationAttributes
  extends Optional<
    UserAttributes,
    | 'id'
    | 'phone'
    | 'avatarUrl'
    | 'role'
    | 'language'
    | 'isActive'
    | 'isBanned'
    | 'banReason'
    | 'refreshToken'
    | 'createdAt'
    | 'updatedAt'
  > {}

// User model class
class User extends Model<UserAttributes, UserCreationAttributes> implements UserAttributes {
  public id!: number;
  public email!: string;
  public passwordHash!: string;
  public phone!: string | null;
  public fullName!: string;
  public avatarUrl!: string | null;
  public role!: UserRole;
  public language!: 'ar' | 'en';
  public isActive!: boolean;
  public isBanned!: boolean;
  public banReason!: string | null;
  public refreshToken!: string | null;
  public createdAt!: Date;
  public updatedAt!: Date;

  // Helper methods
  public isAdmin(): boolean {
    return this.role === USER_ROLES.ADMIN;
  }

  public isProjectOwner(): boolean {
    return this.role === USER_ROLES.PROJECT_OWNER;
  }

  public isCustomer(): boolean {
    return this.role === USER_ROLES.CUSTOMER;
  }

  public canAccess(): boolean {
    return this.isActive && !this.isBanned;
  }

  // Safe user data (without sensitive fields)
  public toSafeJSON() {
    const { passwordHash, refreshToken, ...safeUser } = this.toJSON();
    return safeUser;
  }
}

User.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true,
      },
    },
    passwordHash: {
      type: DataTypes.STRING(255),
      allowNull: false,
      field: 'password_hash',
    },
    phone: {
      type: DataTypes.STRING(20),
      allowNull: true,
    },
    fullName: {
      type: DataTypes.STRING(100),
      allowNull: false,
      field: 'full_name',
    },
    avatarUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      field: 'avatar_url',
    },
    role: {
      type: DataTypes.ENUM(...Object.values(USER_ROLES)),
      defaultValue: USER_ROLES.CUSTOMER,
    },
    language: {
      type: DataTypes.ENUM(...Object.values(LANGUAGES)),
      defaultValue: LANGUAGES.ARABIC,
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'is_active',
    },
    isBanned: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_banned',
    },
    banReason: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'ban_reason',
    },
    refreshToken: {
      type: DataTypes.STRING(500),
      allowNull: true,
      field: 'refresh_token',
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
    tableName: 'users',
    timestamps: true,
    underscored: true,
    indexes: [
      { fields: ['email'] },
      { fields: ['role'] },
      { fields: ['is_active'] },
    ],
  }
);

export default User;
