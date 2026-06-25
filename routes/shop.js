const express = require('express');
const { publicClient, clientForUser } = require('../db/supabase');
const { requireLogin } = require('../middleware/auth');

const router = express.Router();

router.get('/', async (req, res) => {
  const { data: categories } = await publicClient.from('categories').select('*').order('id');
  const { data: featured } = await publicClient
    .from('products')
    .select('*')
    .order('id', { ascending: false })
    .limit(8);
  const { data: banners } = await publicClient
    .from('banners')
    .select('*')
    .eq('active', true)
    .order('sort_order');
  res.render('home', { categories: categories || [], featured: featured || [], banners: banners || [] });
});

router.get('/category/:slug', async (req, res) => {
  const { data: category } = await publicClient
    .from('categories')
    .select('*')
    .eq('slug', req.params.slug)
    .single();
  if (!category) return res.status(404).send('Khong tim thay danh muc');

  let query = publicClient.from('products').select('*').eq('category_id', category.id);

  const sort = req.query.sort;
  if (sort === 'price_asc') query = query.order('price', { ascending: true });
  if (sort === 'price_desc') query = query.order('price', { ascending: false });

  const { data: products } = await query;

  res.render('category', { category, products: products || [], sort: sort || '' });
});

router.get('/product/:id', async (req, res) => {
  const { data: product } = await publicClient
    .from('products')
    .select('*')
    .eq('id', req.params.id)
    .single();
  if (!product) return res.status(404).send('Khong tim thay san pham');

  const { data: category } = await publicClient
    .from('categories')
    .select('*')
    .eq('id', product.category_id)
    .single();

  const { data: related } = await publicClient
    .from('products')
    .select('*')
    .eq('category_id', product.category_id)
    .neq('id', product.id)
    .limit(4);

  res.render('product', { product, category, related: related || [], specs: product.specs || {} });
});

router.get('/search', async (req, res) => {
  const q = (req.query.q || '').trim();
  let products = [];
  if (q) {
    const { data } = await publicClient
      .from('products')
      .select('*')
      .ilike('name', `%${q}%`)
      .order('id', { ascending: false });
    products = data || [];
  }
  res.render('search', { products, q });
});

router.post('/cart/add', requireLogin, (req, res) => {
  const productId = parseInt(req.body.productId, 10);
  const quantity = Math.max(1, parseInt(req.body.quantity, 10) || 1);

  if (!req.session.cart) req.session.cart = [];

  const existing = req.session.cart.find((item) => item.productId === productId);
  if (existing) {
    existing.quantity += quantity;
  } else {
    req.session.cart.push({ productId, quantity });
  }

  res.redirect(req.body.redirectTo || '/cart');
});

router.get('/cart', requireLogin, async (req, res) => {
  const cart = req.session.cart || [];
  const items = [];
  for (const item of cart) {
    const { data: product } = await publicClient
      .from('products')
      .select('*')
      .eq('id', item.productId)
      .single();
    items.push({ ...item, product, subtotal: product ? product.price * item.quantity : 0 });
  }
  const total = items.reduce((sum, item) => sum + item.subtotal, 0);
  res.render('cart', { items, total });
});

router.post('/cart/update', requireLogin, (req, res) => {
  const productId = parseInt(req.body.productId, 10);
  const quantity = Math.max(1, parseInt(req.body.quantity, 10) || 1);
  const cart = req.session.cart || [];
  const item = cart.find((i) => i.productId === productId);
  if (item) item.quantity = quantity;
  res.redirect('/cart');
});

router.post('/cart/remove', requireLogin, (req, res) => {
  const productId = parseInt(req.body.productId, 10);
  req.session.cart = (req.session.cart || []).filter((item) => item.productId !== productId);
  res.redirect('/cart');
});

router.post('/checkout', requireLogin, async (req, res) => {
  const cart = req.session.cart || [];
  if (cart.length === 0) return res.redirect('/cart');

  const items = [];
  for (const item of cart) {
    const { data: product } = await publicClient
      .from('products')
      .select('*')
      .eq('id', item.productId)
      .single();
    if (product) items.push({ product, quantity: item.quantity });
  }

  const total = items.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const userClient = clientForUser(req.session.user.access_token);

  const { data: order, error } = await userClient
    .from('orders')
    .insert({ user_id: req.session.user.id, total })
    .select()
    .single();

  if (error) {
    return res.status(500).send('Loi tao don hang: ' + error.message);
  }

  const orderItems = items.map((item) => ({
    order_id: order.id,
    product_id: item.product.id,
    quantity: item.quantity,
    price: item.product.price,
  }));
  await userClient.from('order_items').insert(orderItems);

  req.session.cart = [];
  res.render('order-success', { orderId: order.id, total });
});

router.get('/orders', requireLogin, async (req, res) => {
  const userClient = clientForUser(req.session.user.access_token);
  const { data: orders } = await userClient
    .from('orders')
    .select('*')
    .eq('user_id', req.session.user.id)
    .order('id', { ascending: false });
  res.render('orders', { orders: orders || [] });
});

module.exports = router;
