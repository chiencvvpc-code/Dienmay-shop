const express = require('express');
const { publicClient, adminClient } = require('../db/supabase');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.get('/products', requireAdmin, async (req, res) => {
  const { data: products } = await publicClient
    .from('products')
    .select('*, categories(name)')
    .order('id', { ascending: false });
  const { data: categories } = await publicClient.from('categories').select('*').order('id');

  const productsWithCategory = (products || []).map((p) => ({
    ...p,
    category_name: p.categories ? p.categories.name : '',
  }));

  res.render('admin-products', { products: productsWithCategory, categories: categories || [] });
});

router.post('/products/add', requireAdmin, async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  const { name, brand, description, price, original_price, image, stock, category_id } = req.body;
  await adminClient.from('products').insert({
    category_id: parseInt(category_id, 10),
    name,
    brand: brand || '',
    description: description || '',
    specs: {},
    price: parseFloat(price) || 0,
    original_price: parseFloat(original_price) || null,
    image: image || '/img/products/default.svg',
    stock: parseInt(stock, 10) || 0,
  });
  res.redirect('/admin/products');
});

router.post('/products/delete', requireAdmin, async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  await adminClient.from('products').delete().eq('id', req.body.productId);
  res.redirect('/admin/products');
});

module.exports = router;
