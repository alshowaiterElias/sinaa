const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('sinaa_dev', 'root', 'root', {
  host: 'localhost',
  dialect: 'mysql'
});

async function main() {
  try {
    const [results] = await sequelize.query("SELECT id, status FROM transactions WHERE id = 2");
    console.log("Transaction 2 values DB:", results);
  } catch (e) {
    console.error("DB error", e);
  } finally {
    sequelize.close();
  }
}
main();
