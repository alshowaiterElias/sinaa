# صنعة (Sina'a) - Implementation Plan

> Detailed technical architecture and development roadmap for the Sina'a family marketplace platform.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Project Structure](#project-structure)
3. [Database Schema](#database-schema)
4. [API Design](#api-design)
5. [Mobile App Structure (Flutter)](#mobile-app-structure-flutter)
6. [Admin Panel Structure (Flutter Web)](#admin-panel-structure-flutter-web)
7. [Development Phases](#development-phases)
8. [Technology Stack Details](#technology-stack-details)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SINA'A ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │   Flutter    │    │   Flutter    │    │      Express.js API      │  │
│  │  Mobile App  │    │ Admin Panel  │    │                          │  │
│  │ (iOS/Android)│    │  (Web Only)  │    │  ┌────────────────────┐  │  │
│  └──────┬───────┘    └──────┬───────┘    │  │   REST Endpoints   │  │  │
│         │                   │            │  └────────────────────┘  │  │
│         │   Independent     │            │  ┌────────────────────┐  │  │
│         │     Projects      │            │  │  WebSocket Server  │  │  │
│         │                   │            │  │   (Real-time Chat) │  │  │
│         └───────────┬───────┘            │  └────────────────────┘  │  │
│                     │                    └──────────┬───────────────┘  │
│                     ▼                               │                  │
│         ┌───────────────────┐◄──────────────────────┘                  │
│         │   Shared API      │                                          │
│         │  (Authentication) │                                          │
│         └─────────┬─────────┘                                          │
│                   │                                                     │
│                   ▼                                                     │
│         ┌───────────────────┐    ┌───────────────────┐                 │
│         │      MySQL        │    │   File Storage    │                 │
│         │    Database       │    │  (Images/Assets)  │                 │
│         └───────────────────┘    └───────────────────┘                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

> Three independent projects sharing a common API

```
Sina'a/
├── backend/                    # Express.js API Server
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── utils/
│   │   └── index.js
│   ├── migrations/
│   ├── seeders/
│   ├── uploads/
│   ├── package.json
│   └── .env
│
├── mobile/                     # Flutter Mobile App (iOS/Android)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── assets/
│   └── pubspec.yaml
│
├── admin/                      # Flutter Admin Panel (Web)
│   ├── lib/
│   ├── web/
│   ├── assets/
│   └── pubspec.yaml
│
└── docs/                       # Documentation
    ├── requirements.md
    ├── implementation_plan.md
    └── task_breakdown.md
```

---

## Database Schema

### Core Tables

#### 1. Users Table
```sql
CREATE TABLE users (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    phone           VARCHAR(20),
    full_name       VARCHAR(100) NOT NULL,
    avatar_url      VARCHAR(500),
    role            ENUM('customer', 'project_owner', 'admin') DEFAULT 'customer',
    language        ENUM('ar', 'en') DEFAULT 'ar',
    is_active       BOOLEAN DEFAULT TRUE,
    is_banned       BOOLEAN DEFAULT FALSE,
    ban_reason      TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### 2. Projects (Businesses) Table
```sql
CREATE TABLE projects (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    owner_id            INT UNIQUE NOT NULL,
    name                VARCHAR(100) NOT NULL,
    name_ar             VARCHAR(100) NOT NULL,
    description         TEXT,
    description_ar      TEXT,
    logo_url            VARCHAR(500),
    cover_url           VARCHAR(500),
    city                VARCHAR(100) NOT NULL,
    latitude            DECIMAL(10, 8),
    longitude           DECIMAL(11, 8),
    working_hours       JSON,  -- {"sunday": {"open": "09:00", "close": "17:00"}, ...}
    social_links        JSON,  -- {"whatsapp": "...", "instagram": "...", ...}
    status              ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    rejection_reason    TEXT,
    average_rating      DECIMAL(2, 1) DEFAULT 0,
    total_reviews       INT DEFAULT 0,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### 3. Categories Table
```sql
CREATE TABLE categories (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    parent_id       INT NULL,
    name            VARCHAR(100) NOT NULL,
    name_ar         VARCHAR(100) NOT NULL,
    icon            VARCHAR(100),
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);
```

#### 4. Products Table
```sql
CREATE TABLE products (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    project_id          INT NOT NULL,
    category_id         INT NOT NULL,
    name                VARCHAR(200) NOT NULL,
    name_ar             VARCHAR(200) NOT NULL,
    description         TEXT,
    description_ar      TEXT,
    base_price          DECIMAL(10, 2) NOT NULL,
    poster_image_url    VARCHAR(500) NOT NULL,
    quantity            INT DEFAULT 0,
    is_available        BOOLEAN DEFAULT TRUE,
    status              ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    rejection_reason    TEXT,
    average_rating      DECIMAL(2, 1) DEFAULT 0,
    total_reviews       INT DEFAULT 0,
    view_count          INT DEFAULT 0,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
```

#### 5. Product Images Table
```sql
CREATE TABLE product_images (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    product_id      INT NOT NULL,
    image_url       VARCHAR(500) NOT NULL,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
```

#### 6. Product Variants Table
```sql
CREATE TABLE product_variants (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    product_id      INT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    name_ar         VARCHAR(100) NOT NULL,
    price_modifier  DECIMAL(10, 2) DEFAULT 0,  -- Added/subtracted from base price
    quantity        INT DEFAULT 0,
    is_available    BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
```

#### 7. Product Tags Table
```sql
CREATE TABLE tags (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(50) NOT NULL,
    name_ar         VARCHAR(50) NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_tags (
    product_id      INT NOT NULL,
    tag_id          INT NOT NULL,
    PRIMARY KEY (product_id, tag_id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
```

### Inquiry Cart Tables

#### 8. Cart Items Table
```sql
CREATE TABLE cart_items (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    user_id         INT NOT NULL,
    product_id      INT NOT NULL,
    variant_id      INT NULL,
    quantity        INT DEFAULT 1,
    note            TEXT,  -- Optional note for this specific product
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_cart_item (user_id, product_id, variant_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL
);
```

### Chat & Messaging Tables

#### 9. Conversations Table
```sql
CREATE TABLE conversations (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    project_id      INT NOT NULL,
    last_message_at TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_conversation (customer_id, project_id),
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
```

#### 10. Messages Table
```sql
CREATE TABLE messages (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    conversation_id INT NOT NULL,
    sender_id       INT NOT NULL,
    content         TEXT NOT NULL,
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Transaction & Review Tables

#### 11. Transactions Table
```sql
CREATE TABLE transactions (
    id                      INT PRIMARY KEY AUTO_INCREMENT,
    conversation_id         INT NOT NULL,
    product_id              INT,  -- Optional, for reference
    initiated_by            INT NOT NULL,
    customer_confirmed      BOOLEAN DEFAULT FALSE,
    seller_confirmed        BOOLEAN DEFAULT FALSE,
    customer_confirmed_at   TIMESTAMP NULL,
    seller_confirmed_at     TIMESTAMP NULL,
    status                  ENUM('pending', 'confirmed', 'disputed', 'cancelled') DEFAULT 'pending',
    auto_confirm_at         TIMESTAMP NOT NULL,  -- When to auto-confirm
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (initiated_by) REFERENCES users(id)
);
```

#### 12. Reviews Table
```sql
CREATE TABLE reviews (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    product_id      INT NOT NULL,
    user_id         INT NOT NULL,
    transaction_id  INT NOT NULL,
    rating          TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment         TEXT,
    status          ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_review (product_id, user_id, transaction_id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);
```

### Support & Admin Tables

#### 13. Support Tickets Table
```sql
CREATE TABLE support_tickets (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    user_id         INT NOT NULL,
    type            ENUM('general', 'dispute', 'report', 'feedback') NOT NULL,
    subject         VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    related_id      INT,  -- Could be transaction_id, product_id, etc.
    related_type    VARCHAR(50),  -- 'transaction', 'product', 'project', 'user'
    status          ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
    assigned_to     INT,  -- Admin user ID
    resolution      TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);
```

#### 14. System Settings Table
```sql
CREATE TABLE system_settings (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    setting_key     VARCHAR(100) UNIQUE NOT NULL,
    setting_value   TEXT NOT NULL,
    description     VARCHAR(255),
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Default settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('auto_confirm_days', '7', 'Days before transaction auto-confirms'),
('max_product_images', '4', 'Maximum images per product (1 poster + 3 additional)'),
('image_max_size_kb', '2048', 'Maximum image size in KB'),
('default_search_radius_km', '50', 'Default search radius in kilometers');
```

#### 15. Notifications Table
```sql
CREATE TABLE notifications (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    user_id         INT NOT NULL,
    type            VARCHAR(50) NOT NULL,  -- 'message', 'transaction', 'review', 'approval', etc.
    title           VARCHAR(200) NOT NULL,
    title_ar        VARCHAR(200) NOT NULL,
    body            TEXT,
    body_ar         TEXT,
    data            JSON,  -- Additional data like IDs
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## API Design

### Base URL Structure
```
/api/v1/...
```

### Authentication Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Customer registration |
| POST | `/auth/register/project-owner` | Project owner registration |
| POST | `/auth/login` | User login |
| POST | `/auth/logout` | User logout |
| POST | `/auth/forgot-password` | Request password reset |
| POST | `/auth/reset-password` | Reset password |
| GET | `/auth/me` | Get current user profile |
| PUT | `/auth/me` | Update current user profile |

### Categories Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/categories` | List all categories (with subcategories) |
| GET | `/categories/:id` | Get category details |
| GET | `/categories/:id/products` | List products in category |

### Products Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | List products (with filters) |
| GET | `/products/:id` | Get product details |
| GET | `/products/search` | Search products |
| GET | `/products/nearby` | Get nearby products |
| POST | `/products` | Create product (project owner) |
| PUT | `/products/:id` | Update product (project owner) |
| DELETE | `/products/:id` | Delete product (project owner) |
| GET | `/products/:id/reviews` | Get product reviews |

### Projects Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects` | List approved projects |
| GET | `/projects/:id` | Get project details |
| GET | `/projects/:id/products` | Get project's products |
| POST | `/projects` | Create project (registration) |
| PUT | `/projects/:id` | Update project (owner) |
| GET | `/my-project` | Get current user's project |

### Cart Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cart` | Get user's cart (grouped by project) |
| POST | `/cart` | Add product to cart |
| PUT | `/cart/:itemId` | Update cart item (quantity/note) |
| DELETE | `/cart/:itemId` | Remove item from cart |
| DELETE | `/cart` | Clear entire cart |
| GET | `/cart/count` | Get cart items count (for badge) |
| POST | `/cart/send-inquiries` | Send inquiry messages for all cart items |

### Chat Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/conversations` | List user's conversations |
| GET | `/conversations/:id` | Get conversation with messages |
| POST | `/conversations` | Start new conversation |
| POST | `/conversations/:id/messages` | Send message |
| PUT | `/conversations/:id/read` | Mark as read |

### Transaction Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/transactions` | Initiate transaction |
| PUT | `/transactions/:id/confirm` | Confirm transaction |
| PUT | `/transactions/:id/dispute` | Dispute transaction |

### Review Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reviews` | Create review |
| PUT | `/reviews/:id` | Update review |
| DELETE | `/reviews/:id` | Delete review |

### Support Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/support/tickets` | List user's tickets |
| POST | `/support/tickets` | Create ticket |
| GET | `/support/tickets/:id` | Get ticket details |

### Notification Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | List notifications |
| PUT | `/notifications/:id/read` | Mark as read |
| PUT | `/notifications/read-all` | Mark all as read |

### Admin Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/dashboard` | Dashboard statistics |
| GET | `/admin/users` | List all users |
| PUT | `/admin/users/:id/ban` | Ban/unban user |
| GET | `/admin/projects` | List projects (all statuses) |
| PUT | `/admin/projects/:id/approve` | Approve project |
| PUT | `/admin/projects/:id/reject` | Reject project |
| GET | `/admin/products` | List products (all statuses) |
| PUT | `/admin/products/:id/approve` | Approve product |
| PUT | `/admin/products/:id/reject` | Reject product |
| GET | `/admin/reviews` | List reviews for moderation |
| PUT | `/admin/reviews/:id/approve` | Approve review |
| PUT | `/admin/reviews/:id/reject` | Reject review |
| CRUD | `/admin/categories` | Category management |
| GET | `/admin/tickets` | List support tickets |
| PUT | `/admin/tickets/:id` | Update ticket status |
| GET | `/admin/settings` | Get system settings |
| PUT | `/admin/settings` | Update system settings |
| GET | `/admin/analytics/*` | Various analytics endpoints |

---

## Mobile App Structure (Flutter)

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── theme.dart
│   │   ├── routes.dart
│   │   └── constants.dart
│   │
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── interceptors/
│   │   ├── storage/
│   │   │   └── local_storage.dart
│   │   ├── localization/
│   │   │   ├── app_localizations.dart
│   │   │   ├── ar.json
│   │   │   └── en.json
│   │   └── utils/
│   │       ├── validators.dart
│   │       ├── formatters.dart
│   │       └── helpers.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── project.dart
│   │   │   ├── product.dart
│   │   │   ├── category.dart
│   │   │   ├── cart_item.dart
│   │   │   ├── conversation.dart
│   │   │   ├── message.dart
│   │   │   ├── review.dart
│   │   │   └── notification.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── product_repository.dart
│   │   │   ├── project_repository.dart
│   │   │   ├── cart_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   └── ...
│   │   └── providers/
│   │       └── ... (state management)
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── project_owner_register_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── home/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── category_grid.dart
│   │   │       ├── featured_products.dart
│   │   │       └── nearby_projects.dart
│   │   │
│   │   ├── search/
│   │   │   ├── screens/
│   │   │   │   ├── search_screen.dart
│   │   │   │   └── filter_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── products/
│   │   │   ├── screens/
│   │   │   │   ├── product_list_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── product_form_screen.dart (for owners)
│   │   │   └── widgets/
│   │   │
│   │   ├── cart/
│   │   │   ├── screens/
│   │   │   │   └── cart_screen.dart
│   │   │   └── widgets/
│   │   │       ├── cart_item_card.dart
│   │   │       ├── cart_project_group.dart
│   │   │       └── cart_badge.dart
│   │   │
│   │   ├── projects/
│   │   │   ├── screens/
│   │   │   │   ├── project_detail_screen.dart
│   │   │   │   ├── my_project_screen.dart
│   │   │   │   └── project_form_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── chat/
│   │   │   ├── screens/
│   │   │   │   ├── conversations_screen.dart
│   │   │   │   └── chat_screen.dart
│   │   │   └── widgets/
│   │   │       ├── message_bubble.dart
│   │   │       └── chat_input.dart
│   │   │
│   │   ├── reviews/
│   │   │   ├── screens/
│   │   │   │   └── review_form_screen.dart
│   │   │   └── widgets/
│   │   │       ├── review_card.dart
│   │   │       └── rating_bar.dart
│   │   │
│   │   ├── transactions/
│   │   │   ├── screens/
│   │   │   │   └── transaction_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── notifications/
│   │   │   ├── screens/
│   │   │   │   └── notifications_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── support/
│   │   │   ├── screens/
│   │   │   │   ├── tickets_screen.dart
│   │   │   │   └── create_ticket_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   └── profile/
│   │       ├── screens/
│   │       │   ├── profile_screen.dart
│   │       │   └── settings_screen.dart
│   │       └── widgets/
│   │
│   └── shared/
│       └── widgets/
│           ├── custom_app_bar.dart
│           ├── loading_indicator.dart
│           ├── error_widget.dart
│           ├── image_picker_widget.dart
│           └── ...
│
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
└── pubspec.yaml
```

---

## Admin Panel Structure (Flutter Web)

```
admin/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── theme.dart
│   │   ├── routes.dart
│   │   └── constants.dart
│   │
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── interceptors/
│   │   ├── storage/
│   │   │   └── local_storage.dart      # Web-specific storage
│   │   ├── localization/
│   │   │   ├── app_localizations.dart
│   │   │   ├── ar.json
│   │   │   └── en.json
│   │   └── utils/
│   │       ├── validators.dart
│   │       ├── formatters.dart
│   │       └── helpers.dart
│   │
│   ├── data/
│   │   ├── models/                     # Same models as mobile
│   │   │   ├── user.dart
│   │   │   ├── project.dart
│   │   │   ├── product.dart
│   │   │   ├── category.dart
│   │   │   ├── review.dart
│   │   │   ├── ticket.dart
│   │   │   └── ...
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── users_repository.dart
│   │   │   ├── projects_repository.dart
│   │   │   ├── products_repository.dart
│   │   │   ├── categories_repository.dart
│   │   │   ├── reviews_repository.dart
│   │   │   ├── tickets_repository.dart
│   │   │   ├── analytics_repository.dart
│   │   │   └── settings_repository.dart
│   │   └── providers/
│   │       └── ... (state management)
│   │
│   ├── layouts/
│   │   ├── admin_layout.dart           # Main layout with sidebar
│   │   ├── sidebar.dart
│   │   └── header.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       └── login_screen.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── screens/
│   │   │   │   └── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── stat_card.dart
│   │   │       ├── analytics_chart.dart
│   │   │       ├── recent_activity.dart
│   │   │       └── quick_actions.dart
│   │   │
│   │   ├── users/
│   │   │   ├── screens/
│   │   │   │   ├── users_list_screen.dart
│   │   │   │   └── user_detail_screen.dart
│   │   │   └── widgets/
│   │   │       └── users_data_table.dart
│   │   │
│   │   ├── projects/
│   │   │   ├── screens/
│   │   │   │   ├── projects_list_screen.dart
│   │   │   │   ├── project_detail_screen.dart
│   │   │   │   └── pending_projects_screen.dart
│   │   │   └── widgets/
│   │   │       └── projects_data_table.dart
│   │   │
│   │   ├── products/
│   │   │   ├── screens/
│   │   │   │   ├── products_list_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── pending_products_screen.dart
│   │   │   └── widgets/
│   │   │       └── products_data_table.dart
│   │   │
│   │   ├── categories/
│   │   │   ├── screens/
│   │   │   │   └── categories_manager_screen.dart
│   │   │   └── widgets/
│   │   │       ├── category_tree.dart
│   │   │       └── category_form.dart
│   │   │
│   │   ├── reviews/
│   │   │   ├── screens/
│   │   │   │   └── reviews_moderation_screen.dart
│   │   │   └── widgets/
│   │   │       └── reviews_data_table.dart
│   │   │
│   │   ├── tickets/
│   │   │   ├── screens/
│   │   │   │   ├── tickets_list_screen.dart
│   │   │   │   └── ticket_detail_screen.dart
│   │   │   └── widgets/
│   │   │       └── tickets_data_table.dart
│   │   │
│   │   ├── analytics/
│   │   │   ├── screens/
│   │   │   │   └── analytics_screen.dart
│   │   │   └── widgets/
│   │   │       ├── user_growth_chart.dart
│   │   │       ├── category_distribution.dart
│   │   │       └── geographic_map.dart
│   │   │
│   │   └── settings/
│   │       ├── screens/
│   │       │   └── settings_screen.dart
│   │       └── widgets/
│   │           └── settings_form.dart
│   │
│   └── shared/
│       └── widgets/
│           ├── data_table.dart         # Reusable data table
│           ├── loading_indicator.dart
│           ├── error_widget.dart
│           ├── confirmation_dialog.dart
│           ├── status_badge.dart
│           ├── action_buttons.dart
│           └── ...
│
├── web/
│   ├── index.html
│   ├── favicon.png
│   └── icons/
├── assets/
│   ├── images/
│   └── icons/
└── pubspec.yaml
```

---

## Development Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Backend project setup (Express.js + MySQL)
- [ ] Flutter mobile project setup
- [ ] Flutter admin panel project setup
- [ ] Database schema implementation
- [ ] Authentication system (JWT)
- [ ] Basic API structure

### Phase 2: Core Features (Weeks 3-5)
- [ ] Categories management
- [ ] Projects/Businesses CRUD
- [ ] Products CRUD with variants
- [ ] Image upload & compression
- [ ] Tags system
- [ ] Inquiry cart system

### Phase 3: Communication (Weeks 6-7)
- [ ] Real-time chat (WebSocket)
- [ ] Conversations management
- [ ] In-app notifications
- [ ] Support ticket system

### Phase 4: Transactions & Reviews (Week 8)
- [ ] Transaction initiation & confirmation
- [ ] Auto-confirm scheduler
- [ ] Review system
- [ ] Dispute handling

### Phase 5: Search & Discovery (Week 9)
- [ ] Location-based search
- [ ] Advanced filtering
- [ ] Search optimization

### Phase 6: Admin Panel (Weeks 10-11)
- [ ] Dashboard with analytics
- [ ] Content moderation
- [ ] User/Project/Product management
- [ ] System settings

### Phase 7: Polish & Testing (Week 12)
- [ ] Localization (AR/EN)
- [ ] RTL support
- [ ] Performance optimization
- [ ] Bug fixes
- [ ] User acceptance testing

---

## Technology Stack Details

### Backend
| Technology | Purpose |
|------------|---------|
| Node.js | Runtime |
| Express.js | Web framework |
| MySQL | Database |
| Sequelize/Knex | ORM/Query builder |
| Socket.io | Real-time communication |
| JWT | Authentication |
| Multer | File uploads |
| Sharp | Image processing |
| Node-cron | Scheduled tasks |

### Mobile App (Flutter)
| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform framework |
| Provider/Riverpod | State management |
| Dio | HTTP client |
| Socket.io-client-dart | Real-time chat |
| Shared Preferences | Local storage |
| Image Picker | Camera/gallery |
| Geolocator | Location services |
| Google Maps Flutter | Maps integration |

### Admin Panel (Flutter Web)
| Technology | Purpose |
|------------|---------|
| Flutter Web | Web framework |
| Provider/Riverpod | State management |
| Dio | HTTP client |
| go_router | Navigation |
| fl_chart | Analytics charts |
| data_table_2 | Data tables |
| shared_preferences_web | Web storage |

---

## Security Considerations

1. **Authentication**: JWT with refresh tokens
2. **Password**: Bcrypt hashing
3. **API**: Rate limiting, input validation
4. **File Uploads**: Type validation, size limits
5. **SQL**: Parameterized queries (prevent injection)
6. **CORS**: Proper configuration
7. **HTTPS**: Required for production

---

## Benefits of Independent Projects

| Aspect | Benefit |
|--------|---------|
| **Independent deployment** | Update mobile without affecting admin, and vice versa |
| **Tailored UI/UX** | Mobile optimized for touch, Admin optimized for desktop |
| **Separate release cycles** | Different approval processes for each platform |
| **Bug isolation** | Issues in one project don't affect the other |
| **Team flexibility** | Different developers can work on each project |
| **Simplified testing** | Each project has its own test suite |
| **Single skill set** | All frontends use Flutter/Dart |
| **Shared API** | Backend ensures data consistency |

---

## Code Sharing Strategy

Although projects are independent, you can share code via:

1. **Shared Dart Package** (optional):
   ```
   Sina'a/
   ├── packages/
   │   └── sinaa_core/          # Shared package
   │       ├── lib/
   │       │   ├── models/      # Shared data models
   │       │   ├── utils/       # Shared utilities
   │       │   └── constants/   # Shared constants
   │       └── pubspec.yaml
   ├── mobile/
   ├── admin/
   └── backend/
   ```

2. **Copy essential files** (simpler):
   - Models can be identical
   - API endpoints constants can be shared
   - Utility functions can be copied

This gives you the flexibility to share code when needed while keeping projects independent.
