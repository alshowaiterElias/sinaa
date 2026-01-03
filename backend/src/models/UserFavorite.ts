import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './User';
import Project from './Project';

// UserFavorite attributes interface
export interface UserFavoriteAttributes {
    id: number;
    userId: number;
    projectId: number;
    createdAt: Date;
}

// Attributes for creation
export interface UserFavoriteCreationAttributes
    extends Optional<UserFavoriteAttributes, 'id' | 'createdAt'> { }

// UserFavorite model class
class UserFavorite
    extends Model<UserFavoriteAttributes, UserFavoriteCreationAttributes>
    implements UserFavoriteAttributes {
    public id!: number;
    public userId!: number;
    public projectId!: number;
    public createdAt!: Date;

    // Associations
    public readonly user?: User;
    public readonly project?: Project;
}

UserFavorite.init(
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
        projectId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            field: 'project_id',
            references: {
                model: 'projects',
                key: 'id',
            },
        },
        createdAt: {
            type: DataTypes.DATE,
            field: 'created_at',
        },
    },
    {
        sequelize,
        tableName: 'user_favorites',
        timestamps: false,
        underscored: true,
        indexes: [
            {
                unique: true,
                fields: ['user_id', 'project_id'],
            },
        ],
    }
);

// Define associations
User.belongsToMany(Project, {
    through: UserFavorite,
    foreignKey: 'userId',
    otherKey: 'projectId',
    as: 'favoriteProjects',
});

Project.belongsToMany(User, {
    through: UserFavorite,
    foreignKey: 'projectId',
    otherKey: 'userId',
    as: 'favoritedBy',
});

UserFavorite.belongsTo(User, { foreignKey: 'userId', as: 'user' });
UserFavorite.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

export default UserFavorite;
