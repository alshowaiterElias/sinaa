import sequelize from './src/config/database';
import Transaction from './src/models/Transaction';

async function main() {
    try {
        const tx = await Transaction.findByPk(2);
        console.log("TX 2 Status is:", tx?.status);
    } catch(e) {
        console.error(e);
    } finally {
        await sequelize.close();
    }
}
main();
