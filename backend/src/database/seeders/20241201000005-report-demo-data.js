'use strict';

// Password hash for: 12345678aA!
const PASSWORD_HASH = '$2a$12$JeR.e6HPOyz/Wp20dRhaNOFUDuX4rx491DtPwmJIcj/PUixiGh68i';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // =============================================
        // 1. Additional Users
        // =============================================
        // Existing users: 2 (Test - project_owner), 3 (Admin), 4 (Customer), 5 (Test3 - project_owner)
        await queryInterface.bulkInsert('users', [
            {
                id: 6,
                email: 'fatima@gmail.com',
                password_hash: PASSWORD_HASH,
                phone: '711111111',
                full_name: 'Fatima Hassan',
                avatar_url: null,
                city: 'Sanaa',
                latitude: 15.3694,
                longitude: 44.1910,
                location_sharing_enabled: true,
                location_updated_at: new Date(),
                role: 'project_owner',
                language: 'ar',
                is_active: true,
                is_banned: false,
                ban_reason: null,
                refresh_token: null,
                is_verified: true,
                verification_token: null,
                verification_token_expires: null,
                notifications_enabled: true,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 7,
                email: 'omar@gmail.com',
                password_hash: PASSWORD_HASH,
                phone: '722222222',
                full_name: 'Omar Khalid',
                avatar_url: null,
                city: 'Aden',
                latitude: 12.7855,
                longitude: 45.0187,
                location_sharing_enabled: true,
                location_updated_at: new Date(),
                role: 'project_owner',
                language: 'en',
                is_active: true,
                is_banned: false,
                ban_reason: null,
                refresh_token: null,
                is_verified: true,
                verification_token: null,
                verification_token_expires: null,
                notifications_enabled: true,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 8,
                email: 'nora@gmail.com',
                password_hash: PASSWORD_HASH,
                phone: '733333333',
                full_name: 'Nora Salem',
                avatar_url: null,
                city: 'Taiz',
                latitude: 13.5792,
                longitude: 44.0220,
                location_sharing_enabled: true,
                location_updated_at: new Date(),
                role: 'customer',
                language: 'ar',
                is_active: true,
                is_banned: false,
                ban_reason: null,
                refresh_token: null,
                is_verified: true,
                verification_token: null,
                verification_token_expires: null,
                notifications_enabled: true,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 9,
                email: 'ahmed@gmail.com',
                password_hash: PASSWORD_HASH,
                phone: '744444444',
                full_name: 'Ahmed Youssef',
                avatar_url: null,
                city: 'Sanaa',
                latitude: 15.3547,
                longitude: 44.2066,
                location_sharing_enabled: true,
                location_updated_at: new Date(),
                role: 'customer',
                language: 'ar',
                is_active: true,
                is_banned: false,
                ban_reason: null,
                refresh_token: null,
                is_verified: true,
                verification_token: null,
                verification_token_expires: null,
                notifications_enabled: true,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 10,
                email: 'layla@gmail.com',
                password_hash: PASSWORD_HASH,
                phone: '755555555',
                full_name: 'Layla Mansour',
                avatar_url: null,
                city: 'Ibb',
                latitude: 13.9669,
                longitude: 44.1735,
                location_sharing_enabled: true,
                location_updated_at: new Date(),
                role: 'customer',
                language: 'en',
                is_active: true,
                is_banned: false,
                ban_reason: null,
                refresh_token: null,
                is_verified: true,
                verification_token: null,
                verification_token_expires: null,
                notifications_enabled: true,
                created_at: new Date(),
                updated_at: new Date(),
            },
        ]);

        // =============================================
        // 2. Additional Projects
        // =============================================
        // Existing projects: 1 (owner: 2), 2 (owner: 5)
        await queryInterface.bulkInsert('projects', [
            {
                id: 3,
                owner_id: 6,
                name: "Fatima's Kitchen",
                name_ar: 'مطبخ فاطمة',
                description: 'Authentic Yemeni homemade dishes, made with love and tradition.',
                description_ar: 'أطباق يمنية منزلية أصيلة، مصنوعة بحب وتقاليد عريقة.',
                logo_url: null,
                cover_url: null,
                city: 'Sanaa',
                latitude: 15.3694,
                longitude: 44.1910,
                working_hours: JSON.stringify({
                    saturday: '08:00-20:00',
                    sunday: '08:00-20:00',
                    monday: '08:00-20:00',
                    tuesday: '08:00-20:00',
                    wednesday: '08:00-20:00',
                    thursday: '08:00-20:00',
                    friday: 'closed',
                }),
                social_links: JSON.stringify({ instagram: 'fatimas_kitchen' }),
                status: 'approved',
                rejection_reason: null,
                disable_reason: null,
                average_rating: 0.0,
                total_reviews: 0,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 4,
                owner_id: 7,
                name: "Omar's Crafts",
                name_ar: 'حرف عمر',
                description: 'Handcrafted Yemeni traditional crafts — silver, pottery, and textiles.',
                description_ar: 'حرف يمنية تقليدية مصنوعة يدوياً — فضة وفخار ونسيج.',
                logo_url: null,
                cover_url: null,
                city: 'Aden',
                latitude: 12.7855,
                longitude: 45.0187,
                working_hours: JSON.stringify({
                    saturday: '09:00-18:00',
                    sunday: '09:00-18:00',
                    monday: '09:00-18:00',
                    tuesday: '09:00-18:00',
                    wednesday: '09:00-18:00',
                    thursday: '09:00-14:00',
                    friday: 'closed',
                }),
                social_links: JSON.stringify({ twitter: 'omars_crafts' }),
                status: 'approved',
                rejection_reason: null,
                disable_reason: null,
                average_rating: 0.0,
                total_reviews: 0,
                created_at: new Date(),
                updated_at: new Date(),
            },
        ]);

        // =============================================
        // 3. Products for new projects
        // =============================================
        await queryInterface.bulkInsert('products', [
            // Fatima's Kitchen (project 3)
            {
                id: 11,
                project_id: 3,
                category_id: 9,  // Homemade Food
                name: 'Yemeni Mandi',
                name_ar: 'مندي يمني',
                description: 'Traditional Yemeni Mandi rice with tender lamb, slow-cooked in tandoor.',
                description_ar: 'أرز مندي يمني تقليدي مع لحم ضأن طري مطبوخ ببطء في التنور.',
                base_price: 85.00,
                poster_image_url: '/uploads/products/mandi_1.jpg',
                quantity: 30,
                is_available: true,
                status: 'approved',
                view_count: 95,
                average_rating: 4.8,
                total_reviews: 5,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 12,
                project_id: 3,
                category_id: 10,  // Sweets & Desserts
                name: 'Bint Al-Sahn',
                name_ar: 'بنت الصحن',
                description: 'Layered honey cake - the most famous Yemeni dessert.',
                description_ar: 'كعكة عسل طبقات — أشهر الحلويات اليمنية.',
                base_price: 55.00,
                poster_image_url: '/uploads/products/bint_alsahn_1.jpg',
                quantity: 40,
                is_available: true,
                status: 'approved',
                view_count: 72,
                average_rating: 4.9,
                total_reviews: 3,
                created_at: new Date(),
                updated_at: new Date(),
            },
            // Omar's Crafts (project 4)
            {
                id: 13,
                project_id: 4,
                category_id: 5,  // Accessories
                name: 'Silver Jambiya',
                name_ar: 'جنبية فضة',
                description: 'Authentic Yemeni silver Jambiya dagger with handmade sheath.',
                description_ar: 'جنبية فضة يمنية أصيلة مع غمد مصنوع يدوياً.',
                base_price: 500.00,
                poster_image_url: '/uploads/products/jambiya_1.jpg',
                quantity: 10,
                is_available: true,
                status: 'approved',
                view_count: 180,
                average_rating: 4.7,
                total_reviews: 4,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 14,
                project_id: 4,
                category_id: 18,  // Pottery & Ceramics
                name: 'Handmade Pottery Set',
                name_ar: 'طقم فخار يدوي',
                description: 'Beautiful handmade pottery set, traditional Yemeni design.',
                description_ar: 'طقم فخار يدوي جميل بتصميم يمني تقليدي.',
                base_price: 120.00,
                poster_image_url: '/uploads/products/pottery_1.jpg',
                quantity: 20,
                is_available: true,
                status: 'approved',
                view_count: 62,
                average_rating: 4.5,
                total_reviews: 2,
                created_at: new Date(),
                updated_at: new Date(),
            },
        ]);

        // =============================================
        // 4. Conversations  (user1_id < user2_id always)
        // =============================================
        await queryInterface.bulkInsert('conversations', [
            // Customer 4 ↔ Project 1 owner (user 2)
            { id: 1, user1_id: 2, user2_id: 4,  project_id: 1, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
            // Customer 8 (Nora) ↔ Project 1 owner (user 2)
            { id: 2, user1_id: 2, user2_id: 8,  project_id: 1, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
            // Customer 9 (Ahmed) ↔ Project 1 owner (user 2)
            { id: 3, user1_id: 2, user2_id: 9,  project_id: 1, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
            // Customer 10 (Layla) ↔ Project 1 owner (user 2)
            { id: 4, user1_id: 2, user2_id: 10, project_id: 1, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
            // Customer 4 ↔ Fatima (Project 3, owner 6)
            { id: 5, user1_id: 4, user2_id: 6,  project_id: 3, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
            // Customer 8 (Nora) ↔ Omar (Project 4, owner 7)
            { id: 6, user1_id: 7, user2_id: 8,  project_id: 4, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
            // Customer 9 ↔ Fatima (Project 3, owner 6)
            { id: 7, user1_id: 6, user2_id: 9,  project_id: 3, last_message_at: new Date(), created_at: new Date(), deleted_by_user1: false, deleted_by_user2: false },
        ]);

        // =============================================
        // 5. Transactions (Orders)
        // =============================================
        const now = new Date();
        const dayAgo = new Date(now - 86400000);
        const twoDaysAgo = new Date(now - 86400000 * 2);
        const threeDaysAgo = new Date(now - 86400000 * 3);
        const weekAgo = new Date(now - 86400000 * 7);

        await queryInterface.bulkInsert('transactions', [
            // === Project 1 Orders (owner: user 2) ===
            // Conv 1: Customer 4 orders
            { id: 1, conversation_id: 1, product_id: 5, initiated_by: 4, status: 'delivered',         preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: twoDaysAgo, created_at: weekAgo },
            { id: 2, conversation_id: 1, product_id: 1, initiated_by: 4, status: 'delivered',         preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: dayAgo,     created_at: weekAgo },
            { id: 3, conversation_id: 1, product_id: 4, initiated_by: 4, status: 'preparing',         preparing_at: dayAgo,       ready_to_deliver_at: null,         delivered_at: null,       created_at: twoDaysAgo },

            // Conv 2: Customer 8 (Nora) orders
            { id: 4, conversation_id: 2, product_id: 5, initiated_by: 8, status: 'delivered',         preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: twoDaysAgo, created_at: weekAgo },
            { id: 5, conversation_id: 2, product_id: 2, initiated_by: 8, status: 'preparing',         preparing_at: dayAgo,       ready_to_deliver_at: null,         delivered_at: null,       created_at: twoDaysAgo },
            { id: 6, conversation_id: 2, product_id: 3, initiated_by: 8, status: 'pending',           preparing_at: null,         ready_to_deliver_at: null,         delivered_at: null,       created_at: now },

            // Conv 3: Customer 9 (Ahmed) orders
            { id: 7,  conversation_id: 3, product_id: 5, initiated_by: 9, status: 'delivered',        preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: dayAgo,     created_at: weekAgo },
            { id: 8,  conversation_id: 3, product_id: 1, initiated_by: 9, status: 'delivered',        preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: dayAgo,     created_at: weekAgo },
            { id: 9,  conversation_id: 3, product_id: 6, initiated_by: 9, status: 'ready_to_deliver', preparing_at: threeDaysAgo, ready_to_deliver_at: dayAgo,       delivered_at: null,       created_at: threeDaysAgo },
            { id: 10, conversation_id: 3, product_id: 7, initiated_by: 9, status: 'preparing',        preparing_at: dayAgo,       ready_to_deliver_at: null,         delivered_at: null,       created_at: twoDaysAgo },

            // Conv 4: Customer 10 (Layla) orders
            { id: 11, conversation_id: 4, product_id: 5, initiated_by: 10, status: 'delivered',        preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: twoDaysAgo, created_at: weekAgo },
            { id: 12, conversation_id: 4, product_id: 1, initiated_by: 10, status: 'preparing',        preparing_at: dayAgo,       ready_to_deliver_at: null,         delivered_at: null,       created_at: twoDaysAgo },
            { id: 13, conversation_id: 4, product_id: 8, initiated_by: 10, status: 'ready_to_deliver', preparing_at: threeDaysAgo, ready_to_deliver_at: dayAgo,       delivered_at: null,       created_at: threeDaysAgo },
            { id: 14, conversation_id: 4, product_id: 2, initiated_by: 10, status: 'pending',          preparing_at: null,         ready_to_deliver_at: null,         delivered_at: null,       created_at: now },

            // === Project 3 Orders (Fatima's Kitchen, owner: user 6) ===
            { id: 15, conversation_id: 5, product_id: 11, initiated_by: 4,  status: 'delivered',        preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: dayAgo,     created_at: weekAgo },
            { id: 16, conversation_id: 5, product_id: 12, initiated_by: 4,  status: 'preparing',        preparing_at: dayAgo,       ready_to_deliver_at: null,         delivered_at: null,       created_at: twoDaysAgo },
            { id: 17, conversation_id: 7, product_id: 11, initiated_by: 9,  status: 'delivered',        preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: twoDaysAgo, created_at: weekAgo },
            { id: 18, conversation_id: 7, product_id: 12, initiated_by: 9,  status: 'ready_to_deliver', preparing_at: threeDaysAgo, ready_to_deliver_at: dayAgo,       delivered_at: null,       created_at: threeDaysAgo },

            // === Project 4 Orders (Omar's Crafts, owner: user 7) ===
            { id: 19, conversation_id: 6, product_id: 13, initiated_by: 8, status: 'delivered',  preparing_at: weekAgo,      ready_to_deliver_at: threeDaysAgo, delivered_at: dayAgo, created_at: weekAgo },
            { id: 20, conversation_id: 6, product_id: 14, initiated_by: 8, status: 'preparing',  preparing_at: dayAgo,       ready_to_deliver_at: null,         delivered_at: null,   created_at: twoDaysAgo },
        ]);

        // =============================================
        // 6. Transaction Messages (so chat shows order cards)
        // =============================================
        const txMessages = [];
        const transactions = [
            { id: 1,  convId: 1, productId: 5,  senderId: 4,  name: 'Ramadan Gift Box', nameAr: 'صندوق هدايا رمضان' },
            { id: 2,  convId: 1, productId: 1,  senderId: 4,  name: 'Traditional Saudi Coffee', nameAr: 'قهوة سعودية تقليدية' },
            { id: 3,  convId: 1, productId: 4,  senderId: 4,  name: 'Oud Perfume Collection', nameAr: 'مجموعة عطور العود' },
            { id: 4,  convId: 2, productId: 5,  senderId: 8,  name: 'Ramadan Gift Box', nameAr: 'صندوق هدايا رمضان' },
            { id: 5,  convId: 2, productId: 2,  senderId: 8,  name: 'Homemade Baklava Box', nameAr: 'علبة بقلاوة منزلية' },
            { id: 6,  convId: 2, productId: 3,  senderId: 8,  name: 'Handwoven Sadu Cushion', nameAr: 'وسادة سدو منسوجة يدوياً' },
            { id: 7,  convId: 3, productId: 5,  senderId: 9,  name: 'Ramadan Gift Box', nameAr: 'صندوق هدايا رمضان' },
            { id: 8,  convId: 3, productId: 1,  senderId: 9,  name: 'Traditional Saudi Coffee', nameAr: 'قهوة سعودية تقليدية' },
            { id: 9,  convId: 3, productId: 6,  senderId: 9,  name: 'Pure Sidr Honey', nameAr: 'عسل سدر نقي' },
            { id: 10, convId: 3, productId: 7,  senderId: 9,  name: 'Embroidered Abaya', nameAr: 'عباية مطرزة' },
            { id: 11, convId: 4, productId: 5,  senderId: 10, name: 'Ramadan Gift Box', nameAr: 'صندوق هدايا رمضان' },
            { id: 12, convId: 4, productId: 1,  senderId: 10, name: 'Traditional Saudi Coffee', nameAr: 'قهوة سعودية تقليدية' },
            { id: 13, convId: 4, productId: 8,  senderId: 10, name: 'Premium Bakhoor Set', nameAr: 'طقم بخور فاخر' },
            { id: 14, convId: 4, productId: 2,  senderId: 10, name: 'Homemade Baklava Box', nameAr: 'علبة بقلاوة منزلية' },
            { id: 15, convId: 5, productId: 11, senderId: 4,  name: 'Yemeni Mandi', nameAr: 'مندي يمني' },
            { id: 16, convId: 5, productId: 12, senderId: 4,  name: 'Bint Al-Sahn', nameAr: 'بنت الصحن' },
            { id: 17, convId: 7, productId: 11, senderId: 9,  name: 'Yemeni Mandi', nameAr: 'مندي يمني' },
            { id: 18, convId: 7, productId: 12, senderId: 9,  name: 'Bint Al-Sahn', nameAr: 'بنت الصحن' },
            { id: 19, convId: 6, productId: 13, senderId: 8,  name: 'Silver Jambiya', nameAr: 'جنبية فضة' },
            { id: 20, convId: 6, productId: 14, senderId: 8,  name: 'Handmade Pottery Set', nameAr: 'طقم فخار يدوي' },
        ];

        for (const tx of transactions) {
            txMessages.push({
                conversation_id: tx.convId,
                sender_id: tx.senderId,
                content: JSON.stringify({
                    transactionId: tx.id,
                    productId: tx.productId,
                    productName: tx.name,
                    productNameAr: tx.nameAr,
                }),
                message_type: 'transaction',
                is_read: true,
                created_at: weekAgo,
            });
        }

        await queryInterface.bulkInsert('messages', txMessages);

        // =============================================
        // 7. Reviews (for delivered transactions only)
        // =============================================
        await queryInterface.bulkInsert('reviews', [
            // Project 1 reviews
            { product_id: 5, user_id: 4,  transaction_id: 1,  rating: 5, comment: 'Amazing gift box, everything was fresh and beautifully packaged!',     status: 'approved', created_at: twoDaysAgo },
            { product_id: 1, user_id: 4,  transaction_id: 2,  rating: 4, comment: 'Great coffee, rich flavor with cardamom.',                              status: 'approved', created_at: dayAgo },
            { product_id: 5, user_id: 8,  transaction_id: 4,  rating: 4, comment: 'Very nice selection, would order again.',                               status: 'approved', created_at: twoDaysAgo },
            { product_id: 5, user_id: 9,  transaction_id: 7,  rating: 5, comment: 'Perfect Ramadan gift for my family. Highly recommended!',               status: 'approved', created_at: dayAgo },
            { product_id: 1, user_id: 9,  transaction_id: 8,  rating: 5, comment: 'Best Arabian coffee I have ever tasted.',                               status: 'approved', created_at: dayAgo },
            { product_id: 5, user_id: 10, transaction_id: 11, rating: 4, comment: 'Nice packaging and quality products inside.',                           status: 'approved', created_at: twoDaysAgo },

            // Project 3 (Fatima) reviews
            { product_id: 11, user_id: 4, transaction_id: 15, rating: 5, comment: 'Best Mandi I ever had! Authentic Yemeni taste.',                        status: 'approved', created_at: dayAgo },
            { product_id: 11, user_id: 9, transaction_id: 17, rating: 5, comment: 'Incredible flavors, the lamb was so tender.',                           status: 'approved', created_at: twoDaysAgo },

            // Project 4 (Omar) reviews
            { product_id: 13, user_id: 8, transaction_id: 19, rating: 5, comment: 'Stunning craftsmanship on the Jambiya. A real treasure.',               status: 'approved', created_at: dayAgo },
        ]);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('reviews', {
            transaction_id: { [Sequelize.Op.in]: [1, 2, 4, 7, 8, 11, 15, 17, 19] },
        }, {});
        await queryInterface.bulkDelete('messages', null, {});
        await queryInterface.bulkDelete('transactions', {
            id: { [Sequelize.Op.between]: [1, 20] },
        }, {});
        await queryInterface.bulkDelete('conversations', {
            id: { [Sequelize.Op.between]: [1, 7] },
        }, {});
        await queryInterface.bulkDelete('products', {
            id: { [Sequelize.Op.between]: [11, 14] },
        }, {});
        await queryInterface.bulkDelete('projects', {
            id: { [Sequelize.Op.in]: [3, 4] },
        }, {});
        await queryInterface.bulkDelete('users', {
            id: { [Sequelize.Op.between]: [6, 10] },
        }, {});
    },
};
