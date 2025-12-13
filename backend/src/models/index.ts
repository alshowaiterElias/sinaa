import User from './User';
import Project from './Project';
import Category from './Category';
import Product from './Product';

// Export all models
export { User, Project, Category, Product };

// Export model types
export type { UserAttributes, UserCreationAttributes } from './User';
export type { ProjectAttributes, ProjectCreationAttributes } from './Project';
export type { CategoryAttributes, CategoryCreationAttributes } from './Category';
export type { ProductAttributes, ProductCreationAttributes } from './Product';

// Initialize associations
const initializeAssociations = (): void => {
  // Associations are already defined in individual model files
  // This function can be extended for complex associations
};

export { initializeAssociations };

export default {
  User,
  Project,
  Category,
  Product,
};
