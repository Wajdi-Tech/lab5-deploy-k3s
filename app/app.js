const express = require('express');
const bodyParser = require('body-parser');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.use(bodyParser.urlencoded({ extended: false }));

// Read DB connection details from environment variables
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'labdb'
});

// Create table if not exists
(async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS submissions (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('Table ready.');
  } catch (err) {
    console.error('Error creating table:', err);
  }
})();

app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, email, created_at FROM submissions ORDER BY id DESC');
    res.render('index', { submissions: result.rows });
  } catch (err) {
    res.status(500).send('DB Error: ' + err.message);
  }
});

app.post('/submit', async (req, res) => {
  const { name, email } = req.body;
  if (!name || !email) return res.redirect('/');
  try {
    await pool.query('INSERT INTO submissions(name, email) VALUES($1, $2)', [name, email]);
    res.redirect('/');
  } catch (err) {
    res.status(500).send('DB Error: ' + err.message);
  }
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});

