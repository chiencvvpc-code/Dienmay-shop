const express = require('express');
const multer = require('multer');
const { publicClient, adminClient, PRODUCT_IMAGE_BUCKET } = require('../db/supabase');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

function buildSpecs(body) {
  const keys = [].concat(body.specKey || []);
  const values = [].concat(body.specValue || []);
  const specs = {};
  keys.forEach((key, i) => {
    if (key && key.trim()) specs[key.trim()] = (values[i] || '').trim();
  });
  return specs;
}

async function uploadImageIfPresent(file) {
  if (!file || !adminClient) return null;
  const fileName = `${Date.now()}-${Math.random().toString(36).slice(2)}-${file.originalname.replace(/\s+/g, '-')}`;
  const { error } = await adminClient.storage
    .from(PRODUCT_IMAGE_BUCKET)
    .upload(fileName, file.buffer, { contentType: file.mimetype });
  if (error) return null;
  const { data } = adminClient.storage.from(PRODUCT_IMAGE_BUCKET).getPublicUrl(fileName);
  return data.publicUrl;
}

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

router.get('/products/edit/:id', requireAdmin, async (req, res) => {
  const { data: product } = await publicClient
    .from('products')
    .select('*')
    .eq('id', req.params.id)
    .single();
  if (!product) return res.status(404).send('Khong tim thay san pham');

  const { data: categories } = await publicClient.from('categories').select('*').order('id');
  res.render('admin-product-edit', { product, categories: categories || [] });
});

router.post('/products/edit/:id', requireAdmin, upload.single('imageFile'), async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  const { name, brand, description, price, original_price, image, stock, category_id, affiliate_url } = req.body;
  const uploadedUrl = await uploadImageIfPresent(req.file);

  await adminClient
    .from('products')
    .update({
      category_id: parseInt(category_id, 10),
      name,
      brand: brand || '',
      description: description || '',
      specs: buildSpecs(req.body),
      price: parseFloat(price) || 0,
      original_price: parseFloat(original_price) || null,
      image: uploadedUrl || image || '/img/products/default.svg',
      stock: parseInt(stock, 10) || 0,
      affiliate_url: affiliate_url || null,
    })
    .eq('id', req.params.id);

  res.redirect('/admin/products');
});

router.post('/products/add', requireAdmin, upload.single('imageFile'), async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  const { name, brand, description, price, original_price, image, stock, category_id, affiliate_url } = req.body;
  const uploadedUrl = await uploadImageIfPresent(req.file);

  await adminClient.from('products').insert({
    category_id: parseInt(category_id, 10),
    name,
    brand: brand || '',
    description: description || '',
    specs: buildSpecs(req.body),
    price: parseFloat(price) || 0,
    original_price: parseFloat(original_price) || null,
    image: uploadedUrl || image || '/img/products/default.svg',
    stock: parseInt(stock, 10) || 0,
    affiliate_url: affiliate_url || null,
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

router.get('/banners', requireAdmin, async (req, res) => {
  const { data: banners } = await publicClient.from('banners').select('*').order('sort_order');
  res.render('admin-banners', { banners: banners || [] });
});

router.post('/banners/add', requireAdmin, upload.single('imageFile'), async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  const { title, link, image, sort_order } = req.body;
  const uploadedUrl = await uploadImageIfPresent(req.file);

  await adminClient.from('banners').insert({
    title: title || '',
    link,
    image: uploadedUrl || image,
    sort_order: parseInt(sort_order, 10) || 0,
    active: true,
  });
  res.redirect('/admin/banners');
});

router.post('/banners/toggle', requireAdmin, async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  const { data: banner } = await adminClient
    .from('banners')
    .select('active')
    .eq('id', req.body.bannerId)
    .single();
  if (banner) {
    await adminClient.from('banners').update({ active: !banner.active }).eq('id', req.body.bannerId);
  }
  res.redirect('/admin/banners');
});

router.post('/banners/delete', requireAdmin, async (req, res) => {
  if (!adminClient) {
    return res.status(500).send('Thieu SUPABASE_SERVICE_ROLE_KEY tren server');
  }
  await adminClient.from('banners').delete().eq('id', req.body.bannerId);
  res.redirect('/admin/banners');
});

module.exports = router;
