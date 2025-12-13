import request from 'supertest';
import app from '../src/index';
import { User, Project, Category } from '../src/models';
import sequelize from '../src/config/database';
import { hashPassword } from '../src/utils/password';
import { generateAccessToken } from '../src/utils/jwt';

const API_PREFIX = '/api/v1';

// Test data generators
const createAdminUser = async () => {
  const passwordHash = await hashPassword('AdminPass123');
  return User.create({
    email: 'admin@test.com',
    passwordHash,
    fullName: 'Test Admin',
    role: 'admin',
  });
};

const createRegularUser = async () => {
  const passwordHash = await hashPassword('UserPass123');
  return User.create({
    email: 'user@test.com',
    passwordHash,
    fullName: 'Test User',
    role: 'customer',
  });
};

const createCategory = async (data: {
  name: string;
  nameAr: string;
  parentId?: number | null;
  icon?: string | null;
  sortOrder?: number;
  isActive?: boolean;
}) => {
  return Category.create({
    name: data.name,
    nameAr: data.nameAr,
    parentId: data.parentId || null,
    icon: data.icon || null,
    sortOrder: data.sortOrder ?? 0,
    isActive: data.isActive ?? true,
  });
};

describe('Categories API', () => {
  // Setup and teardown
  beforeAll(async () => {
    await sequelize.sync({ force: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  beforeEach(async () => {
    // Clear all data before each test
    await Category.destroy({ where: {}, force: true });
    await Project.destroy({ where: {}, force: true });
    await User.destroy({ where: {}, force: true });
  });

  // ==================== Public Endpoints ====================
  describe('GET /categories', () => {
    it('should return empty array when no categories exist', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/categories`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.categories).toEqual([]);
    });

    it('should return categories with subcategories', async () => {
      // Create parent category
      const parent = await createCategory({
        name: 'Food & Beverages',
        nameAr: 'الطعام والمشروبات',
        icon: 'restaurant',
        sortOrder: 1,
      });

      // Create subcategories
      await createCategory({
        name: 'Homemade Food',
        nameAr: 'أكلات منزلية',
        parentId: parent.id,
        sortOrder: 1,
      });

      await createCategory({
        name: 'Sweets',
        nameAr: 'حلويات',
        parentId: parent.id,
        sortOrder: 2,
      });

      const response = await request(app)
        .get(`${API_PREFIX}/categories`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.categories).toHaveLength(1);
      expect(response.body.data.categories[0].name).toBe('Food & Beverages');
      expect(response.body.data.categories[0].children).toHaveLength(2);
    });

    it('should not return inactive categories by default', async () => {
      await createCategory({
        name: 'Active Category',
        nameAr: 'فئة نشطة',
        isActive: true,
      });

      await createCategory({
        name: 'Inactive Category',
        nameAr: 'فئة غير نشطة',
        isActive: false,
      });

      const response = await request(app)
        .get(`${API_PREFIX}/categories`)
        .expect(200);

      expect(response.body.data.categories).toHaveLength(1);
      expect(response.body.data.categories[0].name).toBe('Active Category');
    });

    it('should return categories in sort order', async () => {
      await createCategory({
        name: 'Third',
        nameAr: 'ثالث',
        sortOrder: 3,
      });

      await createCategory({
        name: 'First',
        nameAr: 'أول',
        sortOrder: 1,
      });

      await createCategory({
        name: 'Second',
        nameAr: 'ثاني',
        sortOrder: 2,
      });

      const response = await request(app)
        .get(`${API_PREFIX}/categories`)
        .expect(200);

      expect(response.body.data.categories[0].name).toBe('First');
      expect(response.body.data.categories[1].name).toBe('Second');
      expect(response.body.data.categories[2].name).toBe('Third');
    });
  });

  describe('GET /categories/:id', () => {
    it('should return a single category with children', async () => {
      const parent = await createCategory({
        name: 'Parent Category',
        nameAr: 'فئة أصلية',
      });

      await createCategory({
        name: 'Child Category',
        nameAr: 'فئة فرعية',
        parentId: parent.id,
      });

      const response = await request(app)
        .get(`${API_PREFIX}/categories/${parent.id}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.category.name).toBe('Parent Category');
      expect(response.body.data.category.children).toHaveLength(1);
    });

    it('should return 404 for non-existent category', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/categories/9999`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });

    it('should return 404 for inactive category', async () => {
      const category = await createCategory({
        name: 'Inactive',
        nameAr: 'غير نشط',
        isActive: false,
      });

      const response = await request(app)
        .get(`${API_PREFIX}/categories/${category.id}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should validate ID parameter', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/categories/invalid`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('GET /categories/:id/products', () => {
    it('should return empty products array with category info', async () => {
      const category = await createCategory({
        name: 'Test Category',
        nameAr: 'فئة اختبار',
      });

      const response = await request(app)
        .get(`${API_PREFIX}/categories/${category.id}/products`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.category.id).toBe(category.id);
      expect(response.body.data.products).toEqual([]);
    });

    it('should return 404 for non-existent category', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/categories/9999/products`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Admin Endpoints ====================
  describe('Admin Category Management', () => {
    let adminUser: User;
    let adminToken: string;
    let regularUser: User;
    let regularToken: string;

    beforeEach(async () => {
      adminUser = await createAdminUser();
      adminToken = generateAccessToken({
        userId: adminUser.id,
        email: adminUser.email,
        role: adminUser.role,
      });

      regularUser = await createRegularUser();
      regularToken = generateAccessToken({
        userId: regularUser.id,
        email: regularUser.email,
        role: regularUser.role,
      });
    });

    describe('GET /admin/categories', () => {
      it('should return all categories including inactive for admin', async () => {
        await createCategory({
          name: 'Active',
          nameAr: 'نشط',
          isActive: true,
        });

        await createCategory({
          name: 'Inactive',
          nameAr: 'غير نشط',
          isActive: false,
        });

        const response = await request(app)
          .get(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);

        expect(response.body.success).toBe(true);
        expect(response.body.data.categories).toHaveLength(2);
        expect(response.body.data.stats.total).toBe(2);
        expect(response.body.data.stats.active).toBe(1);
        expect(response.body.data.stats.inactive).toBe(1);
      });

      it('should reject non-admin users', async () => {
        const response = await request(app)
          .get(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${regularToken}`)
          .expect(403);

        expect(response.body.success).toBe(false);
      });

      it('should reject unauthenticated requests', async () => {
        const response = await request(app)
          .get(`${API_PREFIX}/admin/categories`)
          .expect(401);

        expect(response.body.success).toBe(false);
      });
    });

    describe('POST /admin/categories', () => {
      it('should create a new parent category', async () => {
        const response = await request(app)
          .post(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'New Category',
            nameAr: 'فئة جديدة',
            icon: 'star',
          })
          .expect(201);

        expect(response.body.success).toBe(true);
        expect(response.body.data.category.name).toBe('New Category');
        expect(response.body.data.category.nameAr).toBe('فئة جديدة');
        expect(response.body.data.category.icon).toBe('star');
        expect(response.body.data.category.parentId).toBeNull();
      });

      it('should create a subcategory', async () => {
        const parent = await createCategory({
          name: 'Parent',
          nameAr: 'أصلية',
        });

        const response = await request(app)
          .post(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'Subcategory',
            nameAr: 'فرعية',
            parentId: parent.id,
          })
          .expect(201);

        expect(response.body.data.category.parentId).toBe(parent.id);
      });

      it('should not allow creating subcategory of subcategory (3 levels)', async () => {
        const parent = await createCategory({
          name: 'Parent',
          nameAr: 'أصلية',
        });

        const child = await createCategory({
          name: 'Child',
          nameAr: 'فرعية',
          parentId: parent.id,
        });

        const response = await request(app)
          .post(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'Grandchild',
            nameAr: 'حفيدة',
            parentId: child.id,
          })
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.error.message).toContain('Only 2 levels');
      });

      it('should auto-increment sort order', async () => {
        await createCategory({
          name: 'First',
          nameAr: 'أول',
          sortOrder: 5,
        });

        const response = await request(app)
          .post(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'Second',
            nameAr: 'ثاني',
          })
          .expect(201);

        expect(response.body.data.category.sortOrder).toBe(6);
      });

      it('should validate required fields', async () => {
        const response = await request(app)
          .post(`${API_PREFIX}/admin/categories`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'Only English Name',
          })
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
      });
    });

    describe('PUT /admin/categories/:id', () => {
      it('should update a category', async () => {
        const category = await createCategory({
          name: 'Original',
          nameAr: 'أصلي',
        });

        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/${category.id}`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'Updated',
            nameAr: 'محدث',
            icon: 'new_icon',
          })
          .expect(200);

        expect(response.body.data.category.name).toBe('Updated');
        expect(response.body.data.category.nameAr).toBe('محدث');
        expect(response.body.data.category.icon).toBe('new_icon');
      });

      it('should not allow category to be its own parent', async () => {
        const category = await createCategory({
          name: 'Test',
          nameAr: 'اختبار',
        });

        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/${category.id}`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            parentId: category.id,
          })
          .expect(400);

        expect(response.body.error.message).toContain('own parent');
      });

      it('should not convert parent with children to subcategory', async () => {
        const parent = await createCategory({
          name: 'Parent',
          nameAr: 'أصلية',
        });

        await createCategory({
          name: 'Child',
          nameAr: 'فرعية',
          parentId: parent.id,
        });

        const anotherParent = await createCategory({
          name: 'Another Parent',
          nameAr: 'أصلية أخرى',
        });

        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/${parent.id}`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            parentId: anotherParent.id,
          })
          .expect(400);

        expect(response.body.error.message).toContain('subcategories');
      });

      it('should return 404 for non-existent category', async () => {
        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/9999`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            name: 'Test',
          })
          .expect(404);

        expect(response.body.success).toBe(false);
      });
    });

    describe('DELETE /admin/categories/:id', () => {
      it('should delete a category without children', async () => {
        const category = await createCategory({
          name: 'To Delete',
          nameAr: 'للحذف',
        });

        const response = await request(app)
          .delete(`${API_PREFIX}/admin/categories/${category.id}`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);

        expect(response.body.success).toBe(true);

        // Verify deletion
        const deleted = await Category.findByPk(category.id);
        expect(deleted).toBeNull();
      });

      it('should not delete category with subcategories', async () => {
        const parent = await createCategory({
          name: 'Parent',
          nameAr: 'أصلية',
        });

        await createCategory({
          name: 'Child',
          nameAr: 'فرعية',
          parentId: parent.id,
        });

        const response = await request(app)
          .delete(`${API_PREFIX}/admin/categories/${parent.id}`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(400);

        expect(response.body.error.message).toContain('subcategories');
      });

      it('should return 404 for non-existent category', async () => {
        const response = await request(app)
          .delete(`${API_PREFIX}/admin/categories/9999`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(404);

        expect(response.body.success).toBe(false);
      });
    });

    describe('PUT /admin/categories/reorder', () => {
      it('should reorder categories', async () => {
        const cat1 = await createCategory({
          name: 'First',
          nameAr: 'أول',
          sortOrder: 1,
        });

        const cat2 = await createCategory({
          name: 'Second',
          nameAr: 'ثاني',
          sortOrder: 2,
        });

        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/reorder`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            orders: [
              { id: cat1.id, sortOrder: 2 },
              { id: cat2.id, sortOrder: 1 },
            ],
          })
          .expect(200);

        expect(response.body.success).toBe(true);

        // Verify new order
        const updatedCat1 = await Category.findByPk(cat1.id);
        const updatedCat2 = await Category.findByPk(cat2.id);
        expect(updatedCat1?.sortOrder).toBe(2);
        expect(updatedCat2?.sortOrder).toBe(1);
      });

      it('should validate orders array', async () => {
        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/reorder`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            orders: [],
          })
          .expect(400);

        expect(response.body.success).toBe(false);
      });
    });

    describe('PUT /admin/categories/:id/toggle', () => {
      it('should toggle category active status', async () => {
        const category = await createCategory({
          name: 'Active',
          nameAr: 'نشط',
          isActive: true,
        });

        const response = await request(app)
          .put(`${API_PREFIX}/admin/categories/${category.id}/toggle`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);

        expect(response.body.success).toBe(true);
        expect(response.body.data.category.isActive).toBe(false);

        // Toggle back
        const response2 = await request(app)
          .put(`${API_PREFIX}/admin/categories/${category.id}/toggle`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);

        expect(response2.body.data.category.isActive).toBe(true);
      });

      it('should deactivate children when deactivating parent', async () => {
        const parent = await createCategory({
          name: 'Parent',
          nameAr: 'أصلية',
          isActive: true,
        });

        const child = await createCategory({
          name: 'Child',
          nameAr: 'فرعية',
          parentId: parent.id,
          isActive: true,
        });

        await request(app)
          .put(`${API_PREFIX}/admin/categories/${parent.id}/toggle`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);

        // Verify child is also deactivated
        const updatedChild = await Category.findByPk(child.id);
        expect(updatedChild?.isActive).toBe(false);
      });
    });
  });
});

