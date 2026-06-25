const { publicClient } = require('../db/supabase');

function requireLogin(req, res, next) {
  if (!req.session.user) {
    return res.redirect('/login');
  }
  next();
}

function requireAdmin(req, res, next) {
  if (!req.session.user || !req.session.user.is_admin) {
    return res.status(403).send('Khong co quyen truy cap');
  }
  next();
}

async function attachUser(req, res, next) {
  res.locals.currentUser = req.session.user || null;
  res.locals.cartCount = (req.session.cart || []).reduce((sum, item) => sum + item.quantity, 0);
  const { data } = await publicClient.from('categories').select('*').order('id');
  res.locals.allCategories = data || [];
  next();
}

module.exports = { requireLogin, requireAdmin, attachUser };
