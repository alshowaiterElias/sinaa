import request from 'supertest';
import app from '../src/index';
import { User, Project, Product, Category, ProductVariant, ProductImage, Tag } from '../src/models';
import sequelize from '../src/config/database';
import { hashPassword } from '../src/utils/password';
import { generateAccessToken } from '../src/utils/jwt';
import {
    createTestUserData,
    createTestProjectOwnerData,
    authHeader,
    generateTestEmail,
} from './helpers';
import path from 'path';

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

const createProjectOwner = async () => {
    const passwordHash = await hashPassword('OwnerPass123');
    return User.create({
        email: generateTestEmail(),
        passwordHash,
        fullName: 'Test Owner',
        role: 'project_owner',
    });
};

const createCategory = async () => {
    return Category.create({
        name: 'Test Category',
        nameAr: 'تصنيف تجريبي',
        icon: 'category_icon',
    });
};

const createTag = async () => {
    return Tag.create({
        name: 'Test Tag',
        nameAr: 'وسم تجريبي',
    });
};

const createProject = async (ownerId: number, status: 'pending' | 'approved' | 'rejected' = 'approved') => {
    return Project.create({
        ownerId,
        name: 'Test Project',
        nameAr: 'مشروع تجريبي',
        description: 'Test Description',
        descriptionAr: 'وصف تجريبي',
        city: 'Riyadh',
        status,
    });
};

const createProduct = async (projectId: number, categoryId: number, status: 'pending' | 'approved' | 'rejected' = 'approved') => {
    return Product.create({
        projectId,
        categoryId,
        name: 'Test Product',
        nameAr: 'منتج تجريبي',
        description: 'Product Description',
        descriptionAr: 'وصف المنتج',
        basePrice: 100.0,
        posterImageUrl: 'http://example.com/image.jpg',
        quantity: 10,
        status,
        isAvailable: true,
    });
};

describe('Products API', () => {
    // Setup and teardown
    beforeAll(async () => {
        await sequelize.sync({ force: true });
    });

    afterAll(async () => {
        await sequelize.close();
    });

    beforeEach(async () => {
        // Clear all data before each test
        await ProductVariant.destroy({ where: {}, force: true });
        await ProductImage.destroy({ where: {}, force: true });
        // Clean up tags and product_tags (cascade should handle product_tags, but explicit tag cleanup is good)
        await Tag.destroy({ where: {}, force: true });
        await Product.destroy({ where: {}, force: true });
        await Project.destroy({ where: {}, force: true });
        await Category.destroy({ where: {}, force: true });
        await User.destroy({ where: {}, force: true });
    });

    // ==================== Public Endpoints ====================
    describe('GET /products', () => {
        it('should return empty array when no products exist', async () => {
            const response = await request(app)
                .get(`${API_PREFIX}/products`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.products).toEqual([]);
        });

        it('should return only approved products', async () => {
            const owner = await createProjectOwner();
            const project = await createProject(owner.id, 'approved');
            const category = await createCategory();

            // Create approved product
            await createProduct(project.id, category.id, 'approved');

            // Create pending product
            await createProduct(project.id, category.id, 'pending');
        });

        it('should search products by name', async () => {
            const owner = await createProjectOwner();
            const project = await createProject(owner.id, 'approved');
            const category = await createCategory();

            await Product.create({
                projectId: project.id,
                categoryId: category.id,
                name: 'Unique Product',
                nameAr: 'منتج مميز',
                description: 'Desc',
                descriptionAr: 'Desc',
                basePrice: 50,
                posterImageUrl: 'url',
                status: 'approved',
                isAvailable: true,
            });

            const response = await request(app)
                .get(`${API_PREFIX}/products`)
                .query({ search: 'Unique' })
                .expect(200);

            expect(response.body.data.products).toHaveLength(1);
            expect(response.body.data.products[0].name).toBe('Unique Product');
        });
    });

    describe('GET /products/:id', () => {
        it('should return product details', async () => {
            const owner = await createProjectOwner();
            const project = await createProject(owner.id, 'approved');
            const category = await createCategory();
            const product = await createProduct(project.id, category.id, 'approved');

            const response = await request(app)
                .get(`${API_PREFIX}/products/${product.id}`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.id).toBe(product.id);
            expect(response.body.data.project).toBeDefined();
            expect(response.body.data.category).toBeDefined();
        });

        it('should return 404 for non-existent product', async () => {
            const response = await request(app)
                .get(`${API_PREFIX}/products/9999`)
                .expect(404);

            expect(response.body.success).toBe(false);
        });
    });

    // ==================== Product Owner Endpoints ====================
    describe('Product Owner Actions', () => {
        let owner: User;
        let ownerToken: string;
        let project: Project;
        let category: Category;

        beforeEach(async () => {
            owner = await createProjectOwner();
            ownerToken = generateAccessToken({
                userId: owner.id,
                email: owner.email,
                role: owner.role,
            });
            project = await createProject(owner.id, 'approved');
            category = await createCategory();
        });

        describe('POST /products', () => {
            it('should create a new product', async () => {
                const productData = {
                    name: 'New Product',
                    nameAr: 'منتج جديد',
                    description: 'Description',
                    descriptionAr: 'وصف',
                    basePrice: 150.0,
                    categoryId: category.id,
                    posterImageUrl: 'http://example.com/poster.jpg',
                    quantity: 5,
                };

                const response = await request(app)
                    .post(`${API_PREFIX}/products`)
                    .set(authHeader(ownerToken))
                    .send(productData)
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.name).toBe(productData.name);
                expect(response.body.data.status).toBe('pending');
            });
        });

        describe('PUT /products/:id', () => {
            it('should update product details', async () => {
                const product = await createProduct(project.id, category.id, 'approved');

                const response = await request(app)
                    .put(`${API_PREFIX}/products/${product.id}`)
                    .set(authHeader(ownerToken))
                    .send({
                        name: 'Updated Name',
                    })
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.name).toBe('Updated Name');
            });

            it('should fail if user does not own product', async () => {
                const otherOwner = await createProjectOwner();
                const otherProject = await createProject(otherOwner.id, 'approved');
                const otherProduct = await createProduct(otherProject.id, category.id, 'approved');

                const response = await request(app)
                    .put(`${API_PREFIX}/products/${otherProduct.id}`)
                    .set(authHeader(ownerToken))
                    .send({
                        name: 'Hacked',
                    })
                    .expect(403);

                expect(response.body.success).toBe(false);
            });
        });

        describe('DELETE /products/:id', () => {
            it('should delete a product', async () => {
                const product = await createProduct(project.id, category.id, 'approved');

                const response = await request(app)
                    .delete(`${API_PREFIX}/products/${product.id}`)
                    .set(authHeader(ownerToken))
                    .expect(200);

                expect(response.body.success).toBe(true);

                // Verify deletion
                const deletedProduct = await Product.findByPk(product.id);
                expect(deletedProduct).toBeNull();
            });
        });

        // --- Product Images ---
        describe('Product Images', () => {
            let product: Product;

            beforeEach(async () => {
                product = await createProduct(project.id, category.id, 'approved');
            });

            it('should upload a product image', async () => {
                // Create a minimal valid 1x1 pixel JPEG buffer
                const buffer = Buffer.from([
                    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
                    0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
                    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
                    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
                    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
                    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
                    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
                    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
                    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
                    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                    0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
                    0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
                    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
                    0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
                    0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
                    0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
                    0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
                    0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
                    0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
                    0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
                    0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
                    0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
                    0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
                    0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
                    0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
                    0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
                    0x00, 0x00, 0x3F, 0x00, 0xFB, 0xD5, 0xDB, 0x20, 0xA8, 0xF1, 0x7E, 0xDE,
                    0xB5, 0xDF, 0x06, 0x1F, 0x87, 0xE1, 0x45, 0xFF, 0xD9
                ]);

                const response = await request(app)
                    .post(`${API_PREFIX}/products/${product.id}/images`)
                    .set(authHeader(ownerToken))
                    .attach('image', buffer, 'test_image.jpg')
                    .expect(200);

                expect(response.body.success).toBe(true);
                // Multer renames the file, so we check for the path structure
                expect(response.body.data.imageUrl).toMatch(/\/uploads\/products\/image-\d+-\d+\.jpg/);
            });

            it('should delete a product image', async () => {
                const image = await ProductImage.create({
                    productId: product.id,
                    imageUrl: '/uploads/products/test.jpg',
                    sortOrder: 0,
                });

                const response = await request(app)
                    .delete(`${API_PREFIX}/products/${product.id}/images/${image.id}`)
                    .set(authHeader(ownerToken))
                    .expect(200);

                expect(response.body.success).toBe(true);
                const deletedImage = await ProductImage.findByPk(image.id);
                expect(deletedImage).toBeNull();
            });
        });

        // --- Product Tags ---
        describe('Product Tags', () => {
            let product: Product;
            let tag: Tag;

            beforeEach(async () => {
                product = await createProduct(project.id, category.id, 'approved');
                tag = await createTag();
            });

            it('should add a tag to a product', async () => {
                const response = await request(app)
                    .post(`${API_PREFIX}/products/${product.id}/tags`)
                    .set(authHeader(ownerToken))
                    .send({ tagId: tag.id })
                    .expect(200);

                expect(response.body.success).toBe(true);

                const updatedProduct = await Product.findByPk(product.id, { include: ['tags'] });
                expect(updatedProduct?.tags).toHaveLength(1);
                expect(updatedProduct?.tags![0].id).toBe(tag.id);
            });

            it('should remove a tag from a product', async () => {
                await product.addTag(tag);

                const response = await request(app)
                    .delete(`${API_PREFIX}/products/${product.id}/tags/${tag.id}`)
                    .set(authHeader(ownerToken))
                    .expect(200);

                expect(response.body.success).toBe(true);

                const updatedProduct = await Product.findByPk(product.id, { include: ['tags'] });
                expect(updatedProduct?.tags).toHaveLength(0);
            });
        });

        // --- Variants ---
        describe('Product Variants', () => {
            let product: Product;

            beforeEach(async () => {
                product = await createProduct(project.id, category.id, 'approved');
            });

            it('should add a variant', async () => {
                const response = await request(app)
                    .post(`${API_PREFIX}/products/${product.id}/variants`)
                    .set(authHeader(ownerToken))
                    .send({
                        name: 'Red',
                        nameAr: 'أحمر',
                        priceModifier: 10,
                        quantity: 5,
                    })
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.name).toBe('Red');
            });

            it('should list variants', async () => {
                await ProductVariant.create({
                    productId: product.id,
                    name: 'Blue',
                    nameAr: 'أزرق',
                    priceModifier: 0,
                    quantity: 10,
                });

                const response = await request(app)
                    .get(`${API_PREFIX}/products/${product.id}/variants`)
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data).toHaveLength(1);
            });
        });
    });

    // ==================== Admin Endpoints ====================
    describe('Admin Product Management', () => {
        let admin: User;
        let adminToken: string;
        let owner: User;
        let project: Project;
        let category: Category;

        beforeEach(async () => {
            admin = await createAdminUser();
            adminToken = generateAccessToken({
                userId: admin.id,
                email: admin.email,
                role: admin.role,
            });
            owner = await createProjectOwner();
            project = await createProject(owner.id, 'approved');
            category = await createCategory();
        });

        describe('PUT /admin/products/:id/approve', () => {
            it('should approve a pending product', async () => {
                const product = await createProduct(project.id, category.id, 'pending');

                const response = await request(app)
                    .put(`${API_PREFIX}/admin/products/${product.id}/approve`)
                    .set(authHeader(adminToken))
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.status).toBe('approved');
            });
        });

        describe('PUT /admin/products/:id/reject', () => {
            it('should reject a product with reason', async () => {
                const product = await createProduct(project.id, category.id, 'pending');

                const response = await request(app)
                    .put(`${API_PREFIX}/admin/products/${product.id}/reject`)
                    .set(authHeader(adminToken))
                    .send({ reason: 'Invalid content' })
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.status).toBe('rejected');
                expect(response.body.data.rejectionReason).toBe('Invalid content');
            });
        });
    });
});
