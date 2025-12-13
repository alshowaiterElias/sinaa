# صنعة (Sina'a) - Development Task Breakdown

> Detailed checklist of all development tasks organized by phase and component.

---

## Phase 1: Foundation (Weeks 1-2)

### 1.1 Project Setup

#### Backend Setup
- [ ] Initialize Node.js project with Express.js
- [ ] Configure TypeScript (optional but recommended)
- [ ] Set up project folder structure
- [ ] Configure ESLint and Prettier
- [ ] Set up environment variables (.env)
- [ ] Configure MySQL connection
- [ ] Set up Sequelize/Knex ORM
- [ ] Create database migration system
- [ ] Set up logging (Winston/Morgan)
- [ ] Configure CORS

#### Flutter Mobile Setup
- [ ] Create Flutter project (`flutter create mobile`)
- [ ] Set up folder structure (feature-based)
- [ ] Configure linting rules
- [ ] Set up environment configuration (dev/staging/prod)
- [ ] Add core dependencies (Dio, Provider, etc.)
- [ ] Configure localization framework
- [ ] Set up theme system (light/dark, RTL support)
- [ ] Create base widgets and utilities

#### Flutter Admin Panel Setup
- [ ] Create Flutter project (`flutter create admin`)
- [ ] Enable web support
- [ ] Set up folder structure (feature-based)
- [ ] Configure linting rules
- [ ] Set up environment configuration
- [ ] Add core dependencies (Dio, Provider, go_router, fl_chart)
- [ ] Configure localization framework
- [ ] Set up admin theme system
- [ ] Create admin layout with sidebar
- [ ] Create reusable data table widget

---

### 1.2 Database Implementation

#### Core Tables
- [ ] Create users table migration
- [ ] Create projects table migration
- [ ] Create categories table migration
- [ ] Create products table migration
- [ ] Create product_images table migration
- [ ] Create product_variants table migration
- [ ] Create tags table migration
- [ ] Create product_tags table migration
- [ ] Create cart_items table migration

#### Communication Tables
- [ ] Create conversations table migration
- [ ] Create messages table migration

#### Transaction & Review Tables
- [ ] Create transactions table migration
- [ ] Create reviews table migration

#### Support & System Tables
- [ ] Create support_tickets table migration
- [ ] Create notifications table migration
- [ ] Create system_settings table migration
- [ ] Seed default system settings
- [ ] Seed initial admin user

---

### 1.3 Authentication System

#### Backend Auth
- [ ] Implement password hashing (bcrypt)
- [ ] Create JWT token generation
- [ ] Create JWT refresh token mechanism
- [ ] Implement auth middleware
- [ ] Create role-based access middleware
- [ ] POST /auth/register - Customer registration
- [ ] POST /auth/register/project-owner - Project owner registration
- [ ] POST /auth/login - User login
- [ ] POST /auth/logout - User logout
- [ ] POST /auth/forgot-password - Password reset request
- [ ] POST /auth/reset-password - Password reset
- [ ] GET /auth/me - Get current user
- [ ] PUT /auth/me - Update profile

#### Flutter Mobile Auth
- [ ] Create auth repository
- [ ] Create auth state management
- [ ] Build login screen UI
- [ ] Build customer registration screen UI
- [ ] Build project owner registration screen UI
- [ ] Implement secure token storage
- [ ] Implement auto-login on app start
- [ ] Implement logout functionality

#### Flutter Admin Auth
- [ ] Create admin auth repository
- [ ] Create admin auth state management
- [ ] Build admin login screen
- [ ] Implement web token storage
- [ ] Add admin route protection
- [ ] Implement session management
- [ ] Build logout functionality

---

## Phase 2: Core Features (Weeks 3-5)

### 2.1 Categories Management

#### Backend
- [ ] GET /categories - List all with subcategories
- [ ] GET /categories/:id - Get category details
- [ ] GET /categories/:id/products - Products in category
- [ ] POST /admin/categories - Create category
- [ ] PUT /admin/categories/:id - Update category
- [ ] DELETE /admin/categories/:id - Delete category
- [ ] PUT /admin/categories/:id/reorder - Reorder categories

#### Flutter Mobile
- [ ] Create category model
- [ ] Create categories repository
- [ ] Build category grid widget
- [ ] Build category selection widget (for product form)
- [ ] Build category filter in search
- [ ] Integerate with backend

#### Flutter Admin Panel
- [ ] Create category model
- [ ] Create categories repository
- [ ] Build categories list screen
- [ ] Build category form (create/edit dialog)
- [ ] Implement drag-and-drop reordering
- [ ] Build category tree view widget
- [ ] Integerate with backend

---

### 2.2 Projects (Businesses)

#### Backend
- [ ] GET /projects - List approved projects
- [ ] GET /projects/:id - Get project details
- [ ] GET /projects/:id/products - Get project's products
- [ ] GET /my-project - Get current user's project
- [ ] POST /projects - Create project (during registration)
- [ ] PUT /projects/:id - Update project
- [ ] PUT /admin/projects/:id/approve - Approve project
- [ ] PUT /admin/projects/:id/reject - Reject project
- [ ] GET /admin/projects - List all projects (any status)
- [ ] GET /admin/projects/pending - List pending projects

#### Flutter Mobile
- [ ] Create project model
- [ ] Create project repository
- [ ] Build project detail screen
- [ ] Build project card widget
- [ ] Build my project screen (for owners)
- [ ] Build project edit form
- [ ] Build working hours editor
- [ ] Build social links editor
- [ ] Build location picker with map
- [ ] Build pending approval status screen
- [ ] Integerate with backend

#### Flutter Admin Panel
- [ ] Create project model
- [ ] Create projects repository
- [ ] Build projects list screen (data table)
- [ ] Build pending projects queue screen
- [ ] Build project detail/review screen
- [ ] Implement approve/reject actions
- [ ] Build project statistics widgets
- [ ] Integerate with backend

---

### 2.3 Products

#### Backend
- [ ] GET /products - List products (with pagination)
- [ ] GET /products/:id - Get product details
- [ ] GET /products/search - Search products
- [ ] GET /products/nearby - Location-based products
- [ ] POST /products - Create product
- [ ] PUT /products/:id - Update product
- [ ] DELETE /products/:id - Delete product
- [ ] POST /products/:id/images - Add images
- [ ] DELETE /products/:id/images/:imageId - Remove image
- [ ] PUT /admin/products/:id/approve - Approve product
- [ ] PUT /admin/products/:id/reject - Reject product
- [ ] GET /admin/products - List all products
- [ ] GET /admin/products/pending - Pending products

#### Product Variants Backend
- [ ] GET /products/:id/variants - List variants
- [ ] POST /products/:id/variants - Add variant
- [ ] PUT /variants/:id - Update variant
- [ ] DELETE /variants/:id - Delete variant

#### Tags Backend
- [ ] GET /tags - List all tags
- [ ] POST /products/:id/tags - Add tags to product
- [ ] DELETE /products/:id/tags/:tagId - Remove tag

#### Image Processing
- [ ] Set up Multer for file uploads
- [ ] Implement Sharp for image compression
- [ ] Create image validation (type, size)
- [ ] Implement image storage (local/cloud)
- [ ] Create thumbnail generation

#### Flutter Mobile Products
- [ ] Create product model
- [ ] Create variant model
- [ ] Create product repository
- [ ] Build product list screen
- [ ] Build product grid widget
- [ ] Build product card widget
- [ ] Build product detail screen
- [ ] Build product image gallery
- [ ] Build variant selector widget
- [ ] Build product form screen (for owners)
- [ ] Build image picker/upload
- [ ] Build variants editor
- [ ] Build tags input widget
- [ ] Build product pending status indicator

#### Flutter Admin Products
- [ ] Create product model
- [ ] Create products repository
- [ ] Build products list screen (data table)
- [ ] Build pending products queue screen
- [ ] Build product detail/review screen
- [ ] Implement approve/reject actions
- [ ] Build product moderation tools

---

### 2.4 Inquiry Cart

#### Backend
- [ ] Create cart_items table migration
- [ ] GET /cart - Get user's cart (grouped by project)
- [ ] POST /cart - Add product to cart
- [ ] PUT /cart/:itemId - Update cart item (quantity/note)
- [ ] DELETE /cart/:itemId - Remove item from cart
- [ ] DELETE /cart - Clear entire cart
- [ ] GET /cart/count - Get cart items count
- [ ] POST /cart/send-inquiries - Send inquiry messages:
  - [ ] Group cart items by project
  - [ ] Create/find conversation for each project
  - [ ] Generate formatted inquiry message (bilingual)
  - [ ] Send message to each conversation
  - [ ] Clear cart after successful send
  - [ ] Return list of created/updated conversations

#### Flutter Mobile Cart
- [ ] Create cart_item model
- [ ] Create cart repository
- [ ] Create cart state management (provider/riverpod)
- [ ] Build cart screen with items grouped by project
- [ ] Build cart item card widget
- [ ] Build cart project group widget
- [ ] Build add to cart button (for product detail)
- [ ] Build cart badge widget (item count)
- [ ] Implement add to cart functionality
- [ ] Implement update quantity
- [ ] Implement remove from cart
- [ ] Implement clear cart
- [ ] Build send inquiries confirmation dialog
- [ ] Implement send inquiries flow
- [ ] Handle navigation to conversations after sending
- [ ] Build empty cart state

---

## Phase 3: Communication (Weeks 6-7)

### 3.1 Real-time Chat

#### Backend WebSocket
- [ ] Set up Socket.io server
- [ ] Implement connection authentication
- [ ] Create room management (conversation rooms)
- [ ] Implement message sending/receiving
- [ ] Implement typing indicators
- [ ] Implement online/offline status
- [ ] Handle reconnection logic

#### Backend REST
- [ ] GET /conversations - List user's conversations
- [ ] GET /conversations/:id - Get conversation with messages
- [ ] POST /conversations - Start new conversation
- [ ] POST /conversations/:id/messages - Send message (fallback)
- [ ] PUT /conversations/:id/read - Mark as read
- [ ] GET /conversations/:id/messages - Paginated messages

#### Flutter Mobile Chat
- [ ] Create conversation model
- [ ] Create message model
- [ ] Set up Socket.io client
- [ ] Create chat repository
- [ ] Create chat state management
- [ ] Build conversations list screen
- [ ] Build conversation preview widget
- [ ] Build chat screen
- [ ] Build message bubble widget
- [ ] Build chat input widget
- [ ] Implement message sending
- [ ] Implement real-time message receiving
- [ ] Implement typing indicator
- [ ] Implement scroll-to-bottom
- [ ] Implement message timestamps
- [ ] Handle offline message queue

---

### 3.2 In-App Notifications

#### Backend
- [ ] Create notification service
- [ ] GET /notifications - List notifications
- [ ] PUT /notifications/:id/read - Mark as read
- [ ] PUT /notifications/read-all - Mark all as read
- [ ] DELETE /notifications/:id - Delete notification
- [ ] Implement notification triggers:
  - [ ] New message notification
  - [ ] Transaction initiated notification
  - [ ] Transaction confirmed notification
  - [ ] Review received notification
  - [ ] Project approved/rejected notification
  - [ ] Product approved/rejected notification

#### Flutter Mobile
- [ ] Create notification model
- [ ] Create notifications repository
- [ ] Build notifications screen
- [ ] Build notification item widget
- [ ] Implement unread count badge
- [ ] Implement notification click handling

---

### 3.3 Support Ticket System

#### Backend
- [ ] GET /support/tickets - List user's tickets
- [ ] GET /support/tickets/:id - Get ticket details
- [ ] POST /support/tickets - Create ticket
- [ ] GET /admin/tickets - List all tickets
- [ ] PUT /admin/tickets/:id - Update ticket status
- [ ] PUT /admin/tickets/:id/assign - Assign to admin

#### Flutter Mobile
- [ ] Create ticket model
- [ ] Create support repository
- [ ] Build tickets list screen
- [ ] Build create ticket screen
- [ ] Build ticket detail screen

#### Flutter Admin Panel
- [ ] Create ticket model
- [ ] Create tickets repository
- [ ] Build tickets list screen (data table)
- [ ] Build ticket detail screen
- [ ] Implement status updates
- [ ] Implement ticket assignment
- [ ] Build ticket resolution form

---

## Phase 4: Transactions & Reviews (Week 8)

### 4.1 Transaction System

#### Backend
- [ ] POST /transactions - Initiate transaction
- [ ] PUT /transactions/:id/confirm - Confirm transaction
- [ ] PUT /transactions/:id/deny - Deny transaction
- [ ] POST /transactions/:id/dispute - Open dispute
- [ ] GET /transactions - List user's transactions
- [ ] GET /transactions/:id - Get transaction details
- [ ] Implement auto-confirm scheduler (cron job)
- [ ] Create transaction notification triggers

#### Flutter Mobile
- [ ] Create transaction model
- [ ] Create transaction repository
- [ ] Build transaction initiation flow
- [ ] Build pending transactions widget
- [ ] Build transaction confirmation dialog
- [ ] Build dispute form
- [ ] Build transaction history screen

---

### 4.2 Review System

#### Backend
- [ ] POST /reviews - Create review
- [ ] PUT /reviews/:id - Update review
- [ ] DELETE /reviews/:id - Delete review
- [ ] GET /products/:id/reviews - Get product reviews
- [ ] GET /projects/:id/reviews - Get all project reviews
- [ ] PUT /admin/reviews/:id/approve - Approve review
- [ ] PUT /admin/reviews/:id/reject - Reject review
- [ ] Implement rating calculation service:
  - [ ] Calculate product average rating
  - [ ] Calculate project average rating
- [ ] Create review notification triggers

#### Flutter Mobile
- [ ] Create review model
- [ ] Create reviews repository
- [ ] Build rating bar widget
- [ ] Build review card widget
- [ ] Build reviews list widget
- [ ] Build review form screen
- [ ] Build star rating input

#### Flutter Admin Panel
- [ ] Create review model
- [ ] Create reviews repository
- [ ] Build reviews moderation screen (data table)
- [ ] Build review detail dialog
- [ ] Implement approve/reject actions

---

## Phase 5: Search & Discovery (Week 9)

### 5.1 Search Implementation

#### Backend
- [ ] Implement full-text search (MySQL FULLTEXT or external)
- [ ] GET /products/search with parameters:
  - [ ] Query text
  - [ ] Category filter
  - [ ] Subcategory filter
  - [ ] Price range filter
  - [ ] Rating filter
  - [ ] Tags filter
  - [ ] Location filter (lat, lng, radius)
  - [ ] Sort options (price, rating, distance, newest)
  - [ ] Pagination
- [ ] GET /projects/search with similar filters
- [ ] Implement search suggestions
- [ ] Implement search history (optional)

#### Flutter Mobile
- [ ] Build search screen with search bar
- [ ] Build filter bottom sheet
- [ ] Build filter chips
- [ ] Build sort options
- [ ] Build search results list
- [ ] Build location radius selector
- [ ] Build map view for nearby results
- [ ] Implement search state management
- [ ] Build empty state and no results

---

### 5.2 Location Services

#### Backend
- [ ] Implement Haversine distance calculation
- [ ] GET /products/nearby - Products within radius
- [ ] GET /projects/nearby - Projects within radius
- [ ] Create cities/regions reference table
- [ ] GET /locations/cities - List available cities

#### Flutter Mobile
- [ ] Set up Geolocator package
- [ ] Request location permissions
- [ ] Get current user location
- [ ] Set up Google Maps Flutter
- [ ] Build map with markers
- [ ] Build location selection screen
- [ ] Implement location caching

---

## Phase 6: Admin Panel - Flutter Web (Weeks 10-11)

### 6.1 Dashboard

- [ ] Build dashboard screen layout
- [ ] Implement statistics cards:
  - [ ] Total users count
  - [ ] Total projects count
  - [ ] Total products count
  - [ ] Pending approvals count
  - [ ] Open tickets count
- [ ] Build user growth chart (fl_chart)
- [ ] Build registrations timeline
- [ ] Build category distribution chart
- [ ] Build top projects list
- [ ] Build recent activity feed
- [ ] Implement date range filters

---

### 6.2 User Management

- [ ] Build users list screen (data table)
- [ ] Build user detail screen
- [ ] Implement user filters (role, status)
- [ ] Build ban/unban functionality
- [ ] Build user activity log view

---

### 6.3 Analytics

- [ ] Build analytics screen
- [ ] Implement user growth analytics
- [ ] Implement category performance analytics
- [ ] Implement transaction analytics
- [ ] Implement geographic distribution
- [ ] Build export functionality (CSV)

---

### 6.4 System Settings

- [ ] Build settings screen
- [ ] Implement auto-confirm period setting
- [ ] Implement image size limits setting
- [ ] Implement search radius default setting
- [ ] Build cities management
- [ ] Build content policy management

---

## Phase 7: Polish & Testing (Week 12)

### 7.1 Localization

#### Backend
- [ ] Set up i18n middleware
- [ ] Localize error messages
- [ ] Localize notification texts

#### Flutter Mobile
- [ ] Complete Arabic translations
- [ ] Complete English translations
- [ ] Implement RTL layout support
- [ ] Test all screens in both languages
- [ ] Implement language switcher
- [ ] Store language preference

#### Flutter Admin Panel
- [ ] Complete Arabic translations
- [ ] Complete English translations
- [ ] Implement RTL layout support
- [ ] Implement language switcher

---

### 7.2 Performance Optimization

#### Backend
- [ ] Implement API response caching
- [ ] Optimize database queries
- [ ] Add database indexes
- [ ] Implement pagination everywhere
- [ ] Set up rate limiting

#### Flutter Mobile
- [ ] Implement image caching
- [ ] Optimize list rendering
- [ ] Implement lazy loading
- [ ] Profile and fix memory leaks
- [ ] Optimize app startup time

#### Flutter Admin Panel
- [ ] Optimize web bundle size
- [ ] Implement lazy loading for routes
- [ ] Optimize data table performance

---

### 7.3 Testing

#### Backend
- [ ] Write unit tests for services
- [ ] Write integration tests for APIs
- [ ] Test authentication flows
- [ ] Test transaction flow
- [ ] Test review flow
- [ ] Test chat functionality
- [ ] Load testing

#### Flutter Mobile
- [ ] Write unit tests for repositories
- [ ] Write widget tests for key components
- [ ] Integration tests for main flows
- [ ] Test on multiple devices
- [ ] Test RTL layout

#### Flutter Admin Panel
- [ ] Write unit tests for repositories
- [ ] Write widget tests for key components
- [ ] Test all CRUD operations
- [ ] Test moderation workflows
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)

---

### 7.4 Security & Quality

- [ ] Security audit
- [ ] Fix any vulnerabilities
- [ ] Input validation review
- [ ] SQL injection prevention check
- [ ] XSS prevention check
- [ ] API rate limiting verification
- [ ] Error handling review
- [ ] Logging review

---

### 7.5 Documentation

- [ ] API documentation (Swagger/OpenAPI)
- [ ] Database schema documentation
- [ ] Deployment documentation
- [ ] Admin user guide
- [ ] Mobile app user guide

---

### 7.6 Deployment Preparation

- [ ] Set up production environment
- [ ] Configure production database
- [ ] Set up file storage (cloud)
- [ ] Configure SSL certificates
- [ ] Set up CI/CD pipeline
- [ ] Configure monitoring and alerts
- [ ] Prepare app store submissions
- [ ] Deploy admin panel to web hosting
- [ ] Create privacy policy
- [ ] Create terms of service

---

## Summary Statistics

| Phase | Estimated Tasks | Weeks |
|-------|----------------|-------|
| Foundation | ~60 tasks | 2 |
| Core Features (incl. Cart) | ~95 tasks | 3 |
| Communication | ~50 tasks | 2 |
| Transactions & Reviews | ~35 tasks | 1 |
| Search & Discovery | ~25 tasks | 1 |
| Admin Panel | ~30 tasks | 2 |
| Polish & Testing | ~55 tasks | 1 |
| **Total** | **~350 tasks** | **12 weeks** |

---

## Priority Legend

- 🔴 **Critical** - Must have for MVP
- 🟡 **Important** - Should have for launch
- 🟢 **Nice to Have** - Can be added post-launch

---

## Notes

1. **Parallel Development**: 
   - Backend, Mobile, and Admin can be developed in parallel
   - Backend should lead slightly to provide APIs for frontends

2. **Independent Projects**: 
   - Mobile and Admin are separate Flutter projects
   - They share the same API but have independent codebases
   - Consider creating a shared Dart package for models (optional)

3. **MVP Approach**: For faster launch, consider:
   - Skip variants in Phase 1
   - Basic search without advanced filters
   - Simplified analytics

4. **Dependencies**: Some tasks depend on others:
   - Chat depends on Auth
   - Cart depends on Products
   - Cart Send Inquiries depends on Chat (conversations)
   - Reviews depend on Transactions
   - Transactions depend on Chat

5. **Testing Throughout**: Don't leave all testing for the end - test each feature as it's built.

6. **Flutter Web Considerations**:
   - Use `CanvasKit` renderer for better performance
   - Optimize images for web
   - Test on multiple browsers
