require('dotenv').config();
const express = require('express');
const path = require('path');
const cookieSession = require('cookie-session');

const { attachUser } = require('./middleware/auth');
const authRoutes = require('./routes/auth');
const shopRoutes = require('./routes/shop');
const adminRoutes = require('./routes/admin');

const app = express();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(
  cookieSession({
    name: 'session',
    keys: [process.env.SESSION_SECRET || 'dienmay-shop-secret-key-change-me'],
    maxAge: 1000 * 60 * 60 * 24,
  })
);

app.use(attachUser);

app.use('/', authRoutes);
app.use('/', shopRoutes);
app.use('/admin', adminRoutes);

if (!process.env.VERCEL) {
  const PORT = process.env.PORT || 3001;
  app.listen(PORT, () => {
    console.log(`Dien may shop dang chay tai http://localhost:${PORT}`);
  });
}

module.exports = app;
