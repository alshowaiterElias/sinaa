import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import { PROJECT_STATUS } from '../config/constants';
import User from './User';

type ProjectStatus = 'pending' | 'approved' | 'rejected' | 'disabled';

// Working hours structure
interface WorkingHours {
  [day: string]: {
    open: string;
    close: string;
    closed?: boolean;
  };
}

// Social links structure
interface SocialLinks {
  whatsapp?: string;
  instagram?: string;
  twitter?: string;
  facebook?: string;
  website?: string;
}

// Project attributes interface
export interface ProjectAttributes {
  id: number;
  ownerId: number;
  name: string;
  nameAr: string;
  description: string | null;
  descriptionAr: string | null;
  logoUrl: string | null;
  coverUrl: string | null;
  city: string;
  latitude: number | null;
  longitude: number | null;
  workingHours: WorkingHours | null;
  socialLinks: SocialLinks | null;
  status: ProjectStatus;
  rejectionReason: string | null;
  disableReason: string | null;
  averageRating: number;
  totalReviews: number;
  createdAt: Date;
  updatedAt: Date;
}

// Attributes for creation
export interface ProjectCreationAttributes
  extends Optional<
    ProjectAttributes,
    | 'id'
    | 'description'
    | 'descriptionAr'
    | 'logoUrl'
    | 'coverUrl'
    | 'latitude'
    | 'longitude'
    | 'workingHours'
    | 'socialLinks'
    | 'status'
    | 'rejectionReason'
    | 'averageRating'
    | 'totalReviews'
    | 'createdAt'
    | 'updatedAt'
  > { }

// Project model class
class Project
  extends Model<ProjectAttributes, ProjectCreationAttributes>
  implements ProjectAttributes {
  public id!: number;
  public ownerId!: number;
  public name!: string;
  public nameAr!: string;
  public description!: string | null;
  public descriptionAr!: string | null;
  public logoUrl!: string | null;
  public coverUrl!: string | null;
  public city!: string;
  public latitude!: number | null;
  public longitude!: number | null;
  public workingHours!: WorkingHours | null;
  public socialLinks!: SocialLinks | null;
  public status!: ProjectStatus;
  public rejectionReason!: string | null;
  public disableReason!: string | null;
  public averageRating!: number;
  public totalReviews!: number;
  public createdAt!: Date;
  public updatedAt!: Date;

  // Associations
  public readonly owner?: User;

  // Helper methods
  public isApproved(): boolean {
    return this.status === PROJECT_STATUS.APPROVED;
  }

  public isPending(): boolean {
    return this.status === PROJECT_STATUS.PENDING;
  }

  public isRejected(): boolean {
    return this.status === PROJECT_STATUS.REJECTED;
  }
}

Project.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    ownerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      unique: true,
      field: 'owner_id',
      references: {
        model: 'users',
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
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    descriptionAr: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'description_ar',
    },
    logoUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      field: 'logo_url',
    },
    coverUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      field: 'cover_url',
    },
    city: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true,
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true,
    },
    workingHours: {
      type: DataTypes.JSON,
      allowNull: true,
      field: 'working_hours',
    },
    socialLinks: {
      type: DataTypes.JSON,
      allowNull: true,
      field: 'social_links',
    },
    status: {
      type: DataTypes.ENUM(...Object.values(PROJECT_STATUS)),
      defaultValue: PROJECT_STATUS.PENDING,
    },
    rejectionReason: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'rejection_reason',
    },
    disableReason: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'disable_reason',
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
    tableName: 'projects',
    timestamps: true,
    underscored: true,
    indexes: [
      { fields: ['owner_id'] },
      { fields: ['status'] },
      { fields: ['city'] },
      { fields: ['average_rating'] },
    ],
  }
);

// Define associations
User.hasOne(Project, { foreignKey: 'ownerId', as: 'project' });
Project.belongsTo(User, { foreignKey: 'ownerId', as: 'owner' });

export default Project;

