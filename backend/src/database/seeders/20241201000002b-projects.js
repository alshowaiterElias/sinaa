'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.bulkInsert('projects', [
            {
                id: 1,
                owner_id: 2,
                name: 'Elias Al-Showaiter',
                name_ar: 'إلياس الشويطر',
                description: 'Elias description',
                description_ar: 'وصف مشروع الياس',
                logo_url: null,
                cover_url: null,
                city: 'Sanaa',
                latitude: 15.36183295,
                longitude: 44.20617141,
                working_hours: JSON.stringify({
                    friday: '09:00-17:00',
                    monday: '09:00-17:00',
                    sunday: '09:00-17:00',
                    tuesday: '09:00-17:00',
                    saturday: '09:00-17:00',
                    thursday: '09:00-17:00',
                    wednesday: '09:00-17:00',
                }),
                social_links: JSON.stringify({ twitter: 'test' }),
                status: 'approved',
                rejection_reason: null,
                disable_reason: null,
                average_rating: 0.0,
                total_reviews: 0,
                created_at: new Date(),
                updated_at: new Date(),
            },
            {
                id: 2,
                owner_id: 5,
                name: 'Maria Alsoufi',
                name_ar: 'ماريا الصوفي',
                description: 'maria project',
                description_ar: 'مشروع ماريا',
                logo_url: null,
                cover_url: null,
                city: 'Ibb',
                latitude: 13.96105317,
                longitude: 44.17390510,
                working_hours: JSON.stringify({
                    friday: '09:00-17:00',
                    monday: '09:00-17:00',
                    sunday: '09:00-17:00',
                    tuesday: '09:00-17:00',
                    saturday: '09:00-17:00',
                    thursday: '09:00-17:00',
                    wednesday: '09:00-17:00',
                }),
                social_links: JSON.stringify({ website: 'test' }),
                status: 'approved',
                rejection_reason: null,
                disable_reason: null,
                average_rating: 0.0,
                total_reviews: 0,
                created_at: new Date(),
                updated_at: new Date(),
            },
        ]);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('projects', { id: [1, 2] }, {});
    },
};
