import request from 'supertest';
import app from '../src/index';
import { User, Project, Product } from '../src/models';
import sequelize from '../src/config/database';
import { hashPassword } from '../src/utils/password';
import { generateAccessToken } from '../src/utils/jwt';
import {
    createTestUserData,
    createTestProjectOwnerData,
    authHeader,
    generateTestEmail,
} from './helpers';

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

describe('Projects API', () => {
    // Setup and teardown
    beforeAll(async () => {
        await sequelize.sync({ force: true });
    });

    afterAll(async () => {
        await sequelize.close();
    });

    beforeEach(async () => {
        // Clear all data before each test
        await Product.destroy({ where: {}, force: true });
        await Project.destroy({ where: {}, force: true });
        await User.destroy({ where: {}, force: true });
    });

    // ==================== Public Endpoints ====================
    describe('GET /projects', () => {
        it('should return empty array when no projects exist', async () => {
            const response = await request(app)
                .get(`${API_PREFIX}/projects`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data).toEqual([]);
        });

        it('should return only approved projects', async () => {
            const owner = await createProjectOwner();

            // Create approved project
            await createProject(owner.id, 'approved');

            // Create pending project
            const owner2 = await createProjectOwner();
            await createProject(owner2.id, 'pending');

            const response = await request(app)
                .get(`${API_PREFIX}/projects`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data).toHaveLength(1);
            expect(response.body.data[0].status).toBe('approved');
        });

        it('should filter projects by city', async () => {
            const owner1 = await createProjectOwner();
            const project1 = await createProject(owner1.id, 'approved');

            const owner2 = await createProjectOwner();
            const project2 = await Project.create({
                ownerId: owner2.id,
                name: 'Jeddah Project',
                nameAr: 'مشروع جدة',
                city: 'Jeddah',
                status: 'approved',
            });

            const response = await request(app)
                .get(`${API_PREFIX}/projects`)
                .query({ city: 'Jeddah' })
                .expect(200);

            expect(response.body.data).toHaveLength(1);
            expect(response.body.data[0].city).toBe('Jeddah');
        });

        it('should search projects by name', async () => {
            const owner = await createProjectOwner();
            await Project.create({
                ownerId: owner.id,
                name: 'Unique Name',
                nameAr: 'اسم مميز',
                city: 'Riyadh',
                status: 'approved',
            });

            const response = await request(app)
                .get(`${API_PREFIX}/projects`)
                .query({ search: 'Unique' })
                .expect(200);

            expect(response.body.data).toHaveLength(1);
            expect(response.body.data[0].name).toBe('Unique Name');
        });
    });

    describe('GET /projects/:id', () => {
        it('should return project details', async () => {
            const owner = await createProjectOwner();
            const project = await createProject(owner.id, 'approved');

            const response = await request(app)
                .get(`${API_PREFIX}/projects/${project.id}`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.id).toBe(project.id);
            expect(response.body.data.owner).toBeDefined();
        });

        it('should return 404 for non-existent project', async () => {
            const response = await request(app)
                .get(`${API_PREFIX}/projects/9999`)
                .expect(404);

            expect(response.body.success).toBe(false);
        });

        it('should return 404 for pending project (public access)', async () => {
            const owner = await createProjectOwner();
            const project = await createProject(owner.id, 'pending');

            const response = await request(app)
                .get(`${API_PREFIX}/projects/${project.id}`)
                .expect(404);

            expect(response.body.success).toBe(false);
        });
    });

    // ==================== Project Owner Endpoints ====================
    describe('Project Owner Actions', () => {
        let owner: User;
        let ownerToken: string;

        beforeEach(async () => {
            owner = await createProjectOwner();
            ownerToken = generateAccessToken({
                userId: owner.id,
                email: owner.email,
                role: owner.role,
            });
        });

        describe('GET /projects/my-project', () => {
            it('should return owner project', async () => {
                const project = await createProject(owner.id, 'pending');

                const response = await request(app)
                    .get(`${API_PREFIX}/projects/my-project`)
                    .set(authHeader(ownerToken))
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.id).toBe(project.id);
            });

            it('should return 404 if owner has no project', async () => {
                const response = await request(app)
                    .get(`${API_PREFIX}/projects/my-project`)
                    .set(authHeader(ownerToken))
                    .expect(404);

                expect(response.body.success).toBe(false);
            });
        });

        describe('POST /projects', () => {
            it('should create a new project', async () => {
                const projectData = {
                    name: 'New Project',
                    nameAr: 'مشروع جديد',
                    city: 'Riyadh',
                    description: 'Description',
                };

                const response = await request(app)
                    .post(`${API_PREFIX}/projects`)
                    .set(authHeader(ownerToken))
                    .send(projectData)
                    .expect(201);

                expect(response.body.success).toBe(true);
                expect(response.body.data.name).toBe(projectData.name);
                expect(response.body.data.status).toBe('pending');
            });

            it('should fail if user already has a project', async () => {
                await createProject(owner.id);

                const response = await request(app)
                    .post(`${API_PREFIX}/projects`)
                    .set(authHeader(ownerToken))
                    .send({
                        name: 'Another Project',
                        nameAr: 'مشروع آخر',
                        city: 'Riyadh',
                    })
                    .expect(409);

                expect(response.body.success).toBe(false);
            });
        });

        describe('PUT /projects/:id', () => {
            it('should update project details', async () => {
                const project = await createProject(owner.id);

                const response = await request(app)
                    .put(`${API_PREFIX}/projects/${project.id}`)
                    .set(authHeader(ownerToken))
                    .send({
                        description: 'Updated Description',
                    })
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.description).toBe('Updated Description');
            });

            it('should not allow updating status', async () => {
                const project = await createProject(owner.id, 'pending');

                const response = await request(app)
                    .put(`${API_PREFIX}/projects/${project.id}`)
                    .set(authHeader(ownerToken))
                    .send({
                        status: 'approved',
                    })
                    .expect(200);

                // Status should remain pending
                expect(response.body.data.status).toBe('pending');
            });

            it('should fail if user does not own project', async () => {
                const otherOwner = await createProjectOwner();
                const otherProject = await createProject(otherOwner.id);

                const response = await request(app)
                    .put(`${API_PREFIX}/projects/${otherProject.id}`)
                    .set(authHeader(ownerToken))
                    .send({
                        description: 'Hacked',
                    })
                    .expect(403);

                expect(response.body.success).toBe(false);
            });
        });
    });

    // ==================== Admin Endpoints ====================
    describe('Admin Project Management', () => {
        let admin: User;
        let adminToken: string;

        beforeEach(async () => {
            admin = await createAdminUser();
            adminToken = generateAccessToken({
                userId: admin.id,
                email: admin.email,
                role: admin.role,
            });
        });

        describe('GET /admin/projects', () => {
            it('should return all projects', async () => {
                const owner1 = await createProjectOwner();
                await createProject(owner1.id, 'approved');

                const owner2 = await createProjectOwner();
                await createProject(owner2.id, 'pending');

                const response = await request(app)
                    .get(`${API_PREFIX}/admin/projects`)
                    .set(authHeader(adminToken))
                    .expect(200);

                expect(response.body.data).toHaveLength(2);
            });
        });

        describe('GET /admin/projects/pending', () => {
            it('should return only pending projects', async () => {
                const owner1 = await createProjectOwner();
                await createProject(owner1.id, 'approved');

                const owner2 = await createProjectOwner();
                await createProject(owner2.id, 'pending');

                const response = await request(app)
                    .get(`${API_PREFIX}/admin/projects/pending`)
                    .set(authHeader(adminToken))
                    .expect(200);

                expect(response.body.data).toHaveLength(1);
                expect(response.body.data[0].status).toBe('pending');
            });
        });

        describe('PUT /admin/projects/:id/approve', () => {
            it('should approve a pending project', async () => {
                const owner = await createProjectOwner();
                const project = await createProject(owner.id, 'pending');

                const response = await request(app)
                    .put(`${API_PREFIX}/admin/projects/${project.id}/approve`)
                    .set(authHeader(adminToken))
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.status).toBe('approved');
            });
        });

        describe('PUT /admin/projects/:id/reject', () => {
            it('should reject a project with reason', async () => {
                const owner = await createProjectOwner();
                const project = await createProject(owner.id, 'pending');

                const response = await request(app)
                    .put(`${API_PREFIX}/admin/projects/${project.id}/reject`)
                    .set(authHeader(adminToken))
                    .send({ reason: 'Invalid documents' })
                    .expect(200);

                expect(response.body.success).toBe(true);
                expect(response.body.data.status).toBe('rejected');
                expect(response.body.data.rejectionReason).toBe('Invalid documents');
            });

            it('should fail without rejection reason', async () => {
                const owner = await createProjectOwner();
                const project = await createProject(owner.id, 'pending');

                const response = await request(app)
                    .put(`${API_PREFIX}/admin/projects/${project.id}/reject`)
                    .set(authHeader(adminToken))
                    .send({})
                    .expect(400);

                expect(response.body.success).toBe(false);
            });
        });
    });
});
