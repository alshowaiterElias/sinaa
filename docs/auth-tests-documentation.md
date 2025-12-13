# Authentication Tests Documentation

> Comprehensive documentation of all authentication endpoint tests for the Sina'a platform.

---

## Table of Contents

1. [Test Environment Setup](#test-environment-setup)
2. [Database State Lifecycle](#database-state-lifecycle)
3. [Database Impact Overview](#database-impact-overview)
4. [Test Suites](#test-suites)
   - [Customer Registration](#1-customer-registration-tests)
   - [Project Owner Registration](#2-project-owner-registration-tests)
   - [Login](#3-login-tests)
   - [Get Profile](#4-get-profile-tests)
   - [Update Profile](#5-update-profile-tests)
   - [Logout](#6-logout-tests)
   - [Refresh Token](#7-refresh-token-tests)
   - [Change Password](#8-change-password-tests)
   - [Forgot Password](#9-forgot-password-tests)
   - [Admin Login](#10-admin-login-tests)

---

## Test Environment Setup

### Before All Tests
```typescript
beforeAll(async () => {
  app = createTestApp();
  await sequelize.sync({ force: true }); // Creates all tables
});
```
**Database Impact:** Creates/recreates all database tables with `force: true` (drops existing tables first).

### After All Tests
```typescript
afterAll(async () => {
  await sequelize.close();
});
```
**Database Impact:** Closes database connection.

### Before Each Test
```typescript
beforeEach(async () => {
  await Project.destroy({ where: {}, truncate: true, cascade: true });
  await User.destroy({ where: {}, truncate: true, cascade: true });
});
```
**Database Impact:** Clears ALL data from `projects` and `users` tables before each test to ensure isolation.

---

## Database State Lifecycle

### State Flow Diagram
```
┌─────────────────────────────────────────────────────────────────────────┐
│                        TEST SUITE LIFECYCLE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐                                                    │
│  │  beforeAll()    │  Database State: Empty (all tables dropped)        │
│  │  sync({force})  │  → Tables created: users, projects (empty)         │
│  └────────┬────────┘                                                    │
│           │                                                             │
│           ▼                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    FOR EACH TEST                                 │   │
│  │  ┌─────────────────┐                                            │   │
│  │  │  beforeEach()   │  Database State: TRUNCATED                 │   │
│  │  │  truncate all   │  → users: 0 records                        │   │
│  │  └────────┬────────┘  → projects: 0 records                     │   │
│  │           │                                                      │   │
│  │           ▼                                                      │   │
│  │  ┌─────────────────┐                                            │   │
│  │  │  Test Runs      │  Database operations during test           │   │
│  │  │  (it block)     │  → May INSERT/UPDATE/SELECT records        │   │
│  │  └────────┬────────┘                                            │   │
│  │           │                                                      │   │
│  │           ▼                                                      │   │
│  │  ┌─────────────────┐                                            │   │
│  │  │  Test Complete  │  Records created during test remain        │   │
│  │  └────────┬────────┘  (will be cleared by next beforeEach)      │   │
│  │           │                                                      │   │
│  └───────────┼──────────────────────────────────────────────────────┘   │
│              │ (loop for each test)                                     │
│              ▼                                                          │
│  ┌─────────────────┐                                                    │
│  │  afterAll()     │  Database State: Connection closed                 │
│  │  close()        │  → Any remaining data persists until next run      │
│  └─────────────────┘                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Points
- **Before Each Test:** Database is completely empty (0 users, 0 projects)
- **After Each Test:** Records created during test remain until next `beforeEach`
- **Test Isolation:** Each test starts with a clean slate, unaffected by previous tests

---

## Database Impact Overview

| Operation | Tables Affected | Impact |
|-----------|-----------------|--------|
| `sync({ force: true })` | All | Drops and recreates all tables |
| `User.destroy()` | `users` | Removes all user records |
| `Project.destroy()` | `projects` | Removes all project records |
| `User.create()` | `users` | Inserts new user record |
| `Project.create()` | `projects` | Inserts new project record |
| `User.update()` | `users` | Modifies existing user record |

---

## Test Suites

### 1. Customer Registration Tests

**Endpoint:** `POST /api/v1/auth/register`

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After Test 1.1** | 1 (new customer) | 0 |
| **After Test 1.2** | 1 (first registration only) | 0 |
| **After Tests 1.3-1.5** | 0 (validation fails) | 0 |

#### Test 1.1: Successful Registration
```
✅ should register a new customer successfully
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ email, password, fullName, phone, language }` |
| **Expected Status** | `201 Created` |
| **Database Impact** | Creates 1 new record in `users` table |
| **Validates** | - User data returned correctly<br>- Role is `customer`<br>- Access & refresh tokens generated<br>- Password hash NOT returned |

#### Test 1.2: Duplicate Email
```
❌ should fail registration with existing email
```

| Aspect | Details |
|--------|---------|
| **Input** | Same email as existing user |
| **Expected Status** | `409 Conflict` |
| **Database Impact** | 1 user created in first request, second request rejected |
| **Validates** | - Error code is `CONFLICT`<br>- Email uniqueness enforced |

#### Test 1.3: Invalid Email
```
❌ should fail registration with invalid email
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ email: 'invalid-email' }` |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None (validation fails before DB operation) |
| **Validates** | - Error code is `VALIDATION_ERROR`<br>- Email format validation |

#### Test 1.4: Weak Password
```
❌ should fail registration with weak password
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ password: '123' }` |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None (validation fails before DB operation) |
| **Validates** | - Error code is `VALIDATION_ERROR`<br>- Password strength requirements |

#### Test 1.5: Missing Required Fields
```
❌ should fail registration without required fields
```

| Aspect | Details |
|--------|---------|
| **Input** | Only email, missing password & fullName |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None |
| **Validates** | - Required field validation |

---

### 2. Project Owner Registration Tests

**Endpoint:** `POST /api/v1/auth/register/project-owner`

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After Test 2.1** | 1 (project_owner) | 1 (pending status) |
| **After Test 2.2** | 0 (validation fails) | 0 |

#### Test 2.1: Successful Registration
```
✅ should register a new project owner with project
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ email, password, fullName, projectName, projectNameAr, city }` |
| **Expected Status** | `201 Created` |
| **Database Impact** | Creates 1 record in `users` + 1 record in `projects` (transaction) |
| **Validates** | - User role is `project_owner`<br>- Project created with `pending` status<br>- Project linked to user via `ownerId` |

#### Test 2.2: Missing Project Details
```
❌ should fail without project details
```

| Aspect | Details |
|--------|---------|
| **Input** | Missing `projectName`, `projectNameAr`, `city` |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None (transaction rollback if partial failure) |
| **Validates** | - Project fields are required for project owner registration |

---

### 3. Login Tests

**Endpoint:** `POST /api/v1/auth/login`

**Setup:** Each test has a `beforeEach` that creates a user via registration.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After beforeEach** | 1 (from registration) | 0 |
| **After Test 3.1** | 1 (refresh_token updated) | 0 |
| **After Test 3.2** | 1 (unchanged) | 0 |
| **After Test 3.3** | 1 (unchanged) | 0 |
| **After Test 3.4** | 1 (isBanned=true) | 0 |

#### Test 3.1: Successful Login
```
✅ should login successfully with valid credentials
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ email, password }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Updates `refresh_token` field in `users` table |
| **Validates** | - Correct user returned<br>- Access & refresh tokens generated |

#### Test 3.2: Wrong Password
```
❌ should fail login with wrong password
```

| Aspect | Details |
|--------|---------|
| **Input** | Correct email, wrong password |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Error code is `AUTHENTICATION_ERROR` |

#### Test 3.3: Non-existent Email
```
❌ should fail login with non-existent email
```

| Aspect | Details |
|--------|---------|
| **Input** | Email not in database |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Generic error (prevents email enumeration) |

#### Test 3.4: Banned User
```
❌ should fail login for banned user
```

| Aspect | Details |
|--------|---------|
| **Setup** | User created in beforeEach, then `isBanned` set to `true` via `User.update()` |
| **Expected Status** | `403 Forbidden` |
| **Database Impact** | Updates `isBanned` and `banReason` fields |
| **Validates** | - Error message contains "banned"<br>- Ban enforcement |

---

### 4. Get Profile Tests

**Endpoint:** `GET /api/v1/auth/me`

**Setup:** Each test has a `beforeEach` that creates a user via registration and stores the access token.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After beforeEach** | 1 (from registration) | 0 |
| **After All Tests** | 1 (unchanged - read only) | 0 |

#### Test 4.1: Successful Profile Retrieval
```
✅ should return current user profile
```

| Aspect | Details |
|--------|---------|
| **Headers** | `Authorization: Bearer <token>` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Read only (SELECT) |
| **Validates** | - User data returned<br>- Password hash NOT exposed |

#### Test 4.2: Missing Token
```
❌ should fail without authorization token
```

| Aspect | Details |
|--------|---------|
| **Headers** | None |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Authentication required |

#### Test 4.3: Invalid Token
```
❌ should fail with invalid token
```

| Aspect | Details |
|--------|---------|
| **Headers** | `Authorization: Bearer invalid-token` |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Token validation |

---

### 5. Update Profile Tests

**Endpoint:** `PUT /api/v1/auth/me`

**Setup:** Each test has a `beforeEach` that creates a user via registration and stores the access token.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After beforeEach** | 1 (from registration) | 0 |
| **After Test 5.1** | 1 (fullName & language updated) | 0 |
| **After Test 5.2** | 1 (unchanged - validation fails) | 0 |

#### Test 5.1: Successful Update
```
✅ should update user profile
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ fullName: 'Updated Name', language: 'en' }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Updates `full_name` and `language` in `users` table |
| **Validates** | - Updated values returned |

#### Test 5.2: Invalid Phone Format
```
❌ should fail update with invalid phone format
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ phone: 'invalid-phone' }` |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None |
| **Validates** | - Phone format validation (Saudi format) |

---

### 6. Logout Tests

**Endpoint:** `POST /api/v1/auth/logout`

**Setup:** Each test has a `beforeEach` that creates a user via registration and stores the access token.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After beforeEach** | 1 (with refresh_token) | 0 |
| **After Test 6.1** | 1 (refresh_token = NULL) | 0 |
| **After Test 6.2** | 1 (unchanged) | 0 |

#### Test 6.1: Successful Logout
```
✅ should logout successfully
```

| Aspect | Details |
|--------|---------|
| **Headers** | `Authorization: Bearer <token>` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Sets `refresh_token` to `NULL` in `users` table |
| **Validates** | - Success response |

#### Test 6.2: Logout Without Token
```
❌ should fail logout without token
```

| Aspect | Details |
|--------|---------|
| **Headers** | None |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Authentication required |

---

### 7. Refresh Token Tests

**Endpoint:** `POST /api/v1/auth/refresh`

**Setup:** Each test has a `beforeEach` that creates a user via registration and stores the refresh token.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After beforeEach** | 1 (with refresh_token from registration) | 0 |
| **After Test 7.1** | 1 (refresh_token updated to new value) | 0 |
| **After Test 7.2** | 1 (unchanged) | 0 |

#### Test 7.1: Successful Token Refresh
```
✅ should refresh tokens successfully
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ refreshToken: <valid-token> }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Updates `refresh_token` in `users` table with new token |
| **Validates** | - New tokens returned<br>- New refresh token is different from old |

#### Test 7.2: Invalid Refresh Token
```
❌ should fail with invalid refresh token
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ refreshToken: 'invalid-token' }` |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Token validation |

---

### 8. Change Password Tests

**Endpoint:** `PUT /api/v1/auth/change-password`

**Setup:** Each test has a `beforeEach` that creates a user via registration and stores the access token.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Each Test** | 0 | 0 |
| **After beforeEach** | 1 (password: 'TestPass123') | 0 |
| **After Test 8.1** | 1 (password_hash & refresh_token updated) | 0 |
| **After Test 8.2** | 1 (unchanged) | 0 |
| **After Test 8.3** | 1 (unchanged) | 0 |

#### Test 8.1: Successful Password Change
```
✅ should change password successfully
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ currentPassword: 'TestPass123', password: 'NewTestPass456' }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Updates `password_hash` and `refresh_token` in `users` table |
| **Validates** | - New access token returned (re-authentication) |

#### Test 8.2: Wrong Current Password
```
❌ should fail with wrong current password
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ currentPassword: 'WrongPassword', password: 'NewTestPass456' }` |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None |
| **Validates** | - Current password verification |

#### Test 8.3: Weak New Password
```
❌ should fail with weak new password
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ currentPassword: 'TestPass123', password: '123' }` |
| **Expected Status** | `400 Bad Request` |
| **Database Impact** | None |
| **Validates** | - New password strength requirements |

---

### 9. Forgot Password Tests

**Endpoint:** `POST /api/v1/auth/forgot-password`

**Note:** No `beforeEach` setup in this describe block - each test manages its own user creation.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Test 9.1** | 0 | 0 |
| **After Test 9.1 setup** | 1 (registered user) | 0 |
| **After Test 9.1** | 1 (unchanged - read only) | 0 |
| **Before Test 9.2** | 0 (truncated) | 0 |
| **After Test 9.2** | 0 (no user created) | 0 |

#### Test 9.1: Existing Email
```
✅ should return success for existing email
```

| Aspect | Details |
|--------|---------|
| **Setup** | Registers a user before making forgot-password request |
| **Input** | `{ email: <registered-email> }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Read only (would generate reset token in full implementation) |
| **Validates** | - Success response |

#### Test 9.2: Non-existing Email (Security)
```
✅ should return success for non-existing email (prevent enumeration)
```

| Aspect | Details |
|--------|---------|
| **Input** | `{ email: 'nonexistent@example.com' }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | None |
| **Validates** | - Same response for both cases (prevents email enumeration attack) |

---

### 10. Admin Login Tests

**Endpoint:** `POST /api/v1/auth/admin/login`

**Note:** No `beforeEach` setup in this describe block - each test manages its own user creation.

#### Database State
| State | Users | Projects |
|-------|-------|----------|
| **Before Test 10.1** | 0 | 0 |
| **After Test 10.1 setup** | 1 (admin via User.create) | 0 |
| **After Test 10.1** | 1 (refresh_token updated) | 0 |
| **Before Test 10.2** | 0 (truncated) | 0 |
| **After Test 10.2 setup** | 1 (customer via registration) | 0 |
| **After Test 10.2** | 1 (unchanged) | 0 |

#### Test 10.1: Successful Admin Login
```
✅ should login admin successfully
```

| Aspect | Details |
|--------|---------|
| **Setup** | Creates admin user directly via `User.create()` with `role: 'admin'` and hashed password |
| **Input** | `{ email: 'admin@test.com', password: 'AdminPass123' }` |
| **Expected Status** | `200 OK` |
| **Database Impact** | Updates `refresh_token` in `users` table |
| **Validates** | - User role is `admin`<br>- Tokens returned |

#### Test 10.2: Non-admin Rejected
```
❌ should reject non-admin login at admin endpoint
```

| Aspect | Details |
|--------|---------|
| **Setup** | Creates regular customer user via registration endpoint |
| **Expected Status** | `401 Unauthorized` |
| **Database Impact** | None |
| **Validates** | - Admin role required for admin login endpoint |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| **Total Test Cases** | 27 |
| **Success Cases** | 11 |
| **Failure/Validation Cases** | 16 |
| **Tables Affected** | `users`, `projects` |

### Test Breakdown by Suite

| Test Suite | Success | Failure | Total |
|------------|---------|---------|-------|
| Customer Registration | 1 | 4 | 5 |
| Project Owner Registration | 1 | 1 | 2 |
| Login | 1 | 3 | 4 |
| Get Profile | 1 | 2 | 3 |
| Update Profile | 1 | 1 | 2 |
| Logout | 1 | 1 | 2 |
| Refresh Token | 1 | 1 | 2 |
| Change Password | 1 | 2 | 3 |
| Forgot Password | 2 | 0 | 2 |
| Admin Login | 1 | 1 | 2 |
| **TOTAL** | **11** | **16** | **27** |

## Database Operations by Test

| Test Suite | SELECT | INSERT | UPDATE | DELETE |
|------------|--------|--------|--------|--------|
| Registration | ✓ | ✓ (users) | ✓ | - |
| Project Owner Reg | ✓ | ✓✓ (users + projects) | ✓ | - |
| Login | ✓ | - | ✓ (refresh_token, isBanned) | - |
| Get Profile | ✓ | - | - | - |
| Update Profile | ✓ | - | ✓ (fullName, language) | - |
| Logout | ✓ | - | ✓ (refresh_token = NULL) | - |
| Refresh Token | ✓ | - | ✓ (refresh_token) | - |
| Change Password | ✓ | - | ✓ (password_hash, refresh_token) | - |
| Forgot Password | ✓ | - | - | - |
| Admin Login | ✓ | ✓ (admin user) | ✓ (refresh_token) | - |

---

## Final Database State

After all tests complete:

| Aspect | Value |
|--------|-------|
| **Users Table** | May contain 1-2 records from last test |
| **Projects Table** | May contain 0-1 records from last test |
| **Connection** | Closed |
| **Persistence** | Data remains until next test run |

**Note:** The `beforeEach` truncation ensures each test starts clean, but the final test's data persists after `afterAll` closes the connection.

---

## Running Tests

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test -- tests/auth.test.ts

# Run in watch mode
npm run test:watch
```

## Latest Test Results

**Run Date:** December 12, 2025  
**Duration:** ~18 seconds  
**Result:** ✅ All 27 tests passed

### Coverage Report

| File | % Stmts | % Branch | % Funcs | % Lines |
|------|---------|----------|---------|---------|
| **All files** | 59.09 | 27.77 | 41.66 | 56.69 |
| src/controllers/auth.controller.ts | 87.59 | 56.25 | 90.9 | 88.09 |
| src/middleware/auth.ts | 42.1 | 18.18 | 33.33 | 38.88 |
| src/middleware/validate.ts | 95.23 | 50 | 50 | 93.33 |
| src/models/User.ts | 90.9 | 100 | 80 | 90.9 |
| src/models/Project.ts | 72.72 | 100 | 0 | 72.72 |
| src/routes/auth.routes.ts | 100 | 100 | 100 | 100 |
| src/utils/jwt.ts | 80.55 | 44.44 | 71.42 | 75.86 |
| src/utils/password.ts | 36.36 | 0 | 40 | 28.57 |

### Key Observations

- **auth.controller.ts** has high coverage (88% lines) - most auth logic is tested
- **auth.routes.ts** has 100% coverage - all routes are exercised
- **validate.ts** has good coverage (93% lines) - validation logic well tested
- **password.ts** has lower coverage (28% lines) - some utility functions untested

---

## Notes

1. **Test Isolation:** Each test runs in isolation with fresh database state (tables truncated before each test via `beforeEach`).

2. **Truncation Order:** Projects are truncated before Users due to foreign key constraints (`ownerId` references `users.id`).

3. **Security Tests:** Several tests verify security measures:
   - Password not exposed in responses (`passwordHash` undefined)
   - Email enumeration prevention (same response for existing/non-existing emails)
   - Token validation (invalid tokens rejected)
   - Ban enforcement (banned users get 403)

4. **Transaction Safety:** Project owner registration uses database transactions - if user creation succeeds but project creation fails, the user creation is rolled back.

5. **Password Requirements:**
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one number

6. **Test Data:** Uses helper functions to generate unique test data:
   - `createTestUserData()` - generates customer data with unique email
   - `createTestProjectOwnerData()` - generates project owner data with project details
   - `generateTestEmail()` - creates unique email addresses

