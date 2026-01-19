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
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  locationSharingEnabled: boolean;
  notificationsEnabled: boolean;
  locationUpdatedAt: Date | null;
  role: UserRole;
  language: 'ar' | 'en';
  isActive: boolean;
  isBanned: boolean;
  banReason: string | null;
  isVerified: boolean;
  verificationToken: string | null;
  verificationTokenExpires: Date | null;
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
    | 'city'
    | 'latitude'
    | 'longitude'
    | 'locationSharingEnabled'
    | 'notificationsEnabled'
    | 'locationUpdatedAt'
    | 'role'
    | 'language'
    | 'isActive'
    | 'isBanned'
    | 'banReason'
    | 'isVerified'
    | 'verificationToken'
    | 'verificationTokenExpires'
    | 'refreshToken'
    | 'createdAt'
    | 'updatedAt'
  > { }

// User model class
class User extends Model<UserAttributes, UserCreationAttributes> implements UserAttributes {
  public id!: number;
  public email!: string;
  public passwordHash!: string;
  public phone!: string | null;
  public fullName!: string;
  public avatarUrl!: string | null;
  public city!: string | null;
  public latitude!: number | null;
  public longitude!: number | null;
  public locationSharingEnabled!: boolean;
  public notificationsEnabled!: boolean;
  public locationUpdatedAt!: Date | null;
  public role!: UserRole;
  public language!: 'ar' | 'en';
  public isActive!: boolean;
  public isBanned!: boolean;
  public banReason!: string | null;
  public isVerified!: boolean;
  public verificationToken!: string | null;
  public verificationTokenExpires!: Date | null;
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
    city: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true,
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true,
    },
    locationSharingEnabled: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'location_sharing_enabled',
    },
    notificationsEnabled: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'notifications_enabled',
    },
    locationUpdatedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'location_updated_at',
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
    isVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_verified',
    },
    verificationToken: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: 'verification_token',
    },
    verificationTokenExpires: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'verification_token_expires',
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
      { fields: ['city'] },
      { fields: ['latitude', 'longitude'] },
    ],
  }
);

export default User;
