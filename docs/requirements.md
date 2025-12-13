# صنعة (Sina'a) - Requirements Specification

> A family-based marketplace platform connecting home businesses with local customers.

---

## Core Platform

| Aspect | Specification |
|--------|---------------|
| **Name** | صنعة (Sina'a) |
| **Platforms** | Flutter Mobile (iOS/Android) + Flutter Admin (Web) - Independent projects |
| **Languages** | Arabic & English (RTL support) |
| **Backend** | Express.js + MySQL (shared API) |

---

## Users & Authentication

| Aspect | Specification |
|--------|---------------|
| **Customer** | Standard registration, browse & chat |
| **Project Owner** | Separate registration flow, admin approval required, 1 project max |
| **Admin** | Full system control via web panel |
| **Social Login** | ❌ Not needed |

---

## Categories & Products

| Aspect | Specification |
|--------|---------------|
| **Categories** | 2-level admin-defined hierarchy |
| **Tags** | Seller-defined, flexible |
| **Product Images** | 1 poster + 3 additional (auto-compressed) |
| **Variants** | ✅ Supported |
| **Pricing** | Fixed |
| **Stock** | Quantity-based ("Only 5 left") |

---

## Projects (Businesses)

| Aspect | Specification |
|--------|---------------|
| **Profile Info** | Description, working hours, social links |
| **Location** | Exact coordinates + city |
| **Approval** | Admin required, rejection = new submission needed |
| **Rating** | Average of product ratings |

---

## Reviews & Transactions

| Aspect | Specification |
|--------|---------------|
| **Product Reviews** | ⭐ 1-5 stars + comments |
| **Verification** | Mutual confirmation system |
| **Auto-confirm Period** | Admin configurable (default 7 days) |
| **Disputes** | Ticket-based, admin reviews chat history |

### Transaction Verification Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    TRANSACTION FLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Customer & Seller chat about product                    │
│                         ↓                                   │
│  2. Either party can initiate "Mark as Transaction"         │
│                         ↓                                   │
│  3. Waiting for confirmation (configurable window)          │
│          ↓                              ↓                   │
│   ✅ Both confirm              ❌ One party doesn't respond│
│          ↓                              ↓                   │
│   Review unlocked              AUTO-CONFIRM after period    │
│                                 Review unlocked             │
│                                                             │
│  4. DISPUTE OPTION: If seller denies, customer can:         │
│          ↓                                                  │
│     Open a dispute ticket → Admin reviews chat history      │
│          ↓                                                  │
│     Admin decides if transaction happened                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Inquiry Cart

| Aspect | Specification |
|--------|---------------|
| **Purpose** | Collect products of interest, send batch inquiries |
| **Payment** | ❌ No payment - inquiry only |
| **Grouping** | Products grouped by project in cart |
| **Variants** | ✅ Can add specific variant to cart |
| **Notes** | Optional note per product |
| **Action** | "Send Inquiries" creates conversations & sends messages |

### Inquiry Cart Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    INQUIRY CART FLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. User browses products                                   │
│                    ↓                                        │
│  2. Clicks "Add to Cart" on products of interest            │
│     (cart badge shows count in app bar)                     │
│                    ↓                                        │
│  3. Opens Cart screen                                       │
│     Products grouped by Project:                            │
│     ┌─────────────────────────────┐                        │
│     │ 🏪 Project A                │                        │
│     │   • Product 1 (qty: 2)      │                        │
│     │   • Product 2 (qty: 1)      │                        │
│     ├─────────────────────────────┤                        │
│     │ 🏪 Project B                │                        │
│     │   • Product 3 (qty: 1)      │                        │
│     └─────────────────────────────┘                        │
│                    ↓                                        │
│  4. User clicks "Send Inquiries"                            │
│                    ↓                                        │
│  5. System for EACH project:                                │
│     - Creates/finds existing conversation                   │
│     - Sends formatted inquiry message                       │
│                    ↓                                        │
│  6. User redirected to conversations list                   │
│     Cart cleared after sending                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Communication

| Aspect | Specification |
|--------|---------------|
| **Chat** | Real-time, text-only, general conversations |
| **Notifications** | In-app only |
| **Support** | Ticket system |

---

## Search & Discovery

| Aspect | Specification |
|--------|---------------|
| **Location-based** | ✅ Yes |
| **Filters** | Advanced (price, rating, category, location) |
| **Featured/Promoted** | ❌ Not needed |

---

## Admin Panel

| Capability | Status |
|------------|--------|
| Approve/Reject projects | ✅ |
| Manage categories | ✅ |
| Moderate products/reviews | ✅ |
| Ban users | ✅ |
| Handle disputes | ✅ |
| Configure system settings | ✅ |
| View analytics | ✅ |

---

## Admin Analytics Dashboard

- 📊 Users, Projects, Products counts
- 📈 User growth over time
- 🏷️ Popular categories
- 💬 Transaction/sales activity
- 🎫 Support ticket metrics

---

## Content Policies

| Category | Policy |
|----------|--------|
| **Prohibited** | Weapons, alcohol, tobacco, adult content, medications |
| **Restricted** | Items requiring licenses |
| **Food Safety** | Disclaimer that app isn't responsible for food safety |
| **Copyright** | No counterfeit/branded items |

---

## Technical Specifications

### Image Handling
- **Poster Image**: Required, primary product image
- **Additional Images**: Up to 3 optional images
- **Compression**: Auto-compress on upload
- **Recommended Size**: 1080x1080px (1:1 ratio) for products

### Location
- **Exact Location**: GPS coordinates (latitude/longitude)
- **City**: Selectable from predefined list
- **Search Radius**: Configurable for location-based search
