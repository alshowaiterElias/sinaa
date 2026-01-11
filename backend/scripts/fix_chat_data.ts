import { sequelize } from '../src/config/database';
import Conversation from '../src/models/Conversation';
import Message from '../src/models/Message';

const fixChatData = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Database connection established successfully.');

        const conversations = await Conversation.findAll();
        console.log(`Found ${conversations.length} conversations.`);

        for (const conversation of conversations) {
            console.log(`Processing conversation ${conversation.id}...`);
            const messages = await Message.findAll({
                where: { conversationId: conversation.id },
                order: [['createdAt', 'ASC']],
            });

            console.log(`  Found ${messages.length} messages.`);

            for (let i = 0; i < messages.length; i++) {
                const message = messages[i];
                // Alternate sender between user1 and user2
                const newSenderId = i % 2 === 0 ? conversation.user1Id : conversation.user2Id;

                if (message.senderId !== newSenderId) {
                    await message.update({ senderId: newSenderId });
                    console.log(`    Message ${message.id}: Updated senderId to ${newSenderId}`);
                }
            }
        }

        console.log('✅ Chat data fixed successfully.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error fixing chat data:', error);
        process.exit(1);
    }
};

fixChatData();
