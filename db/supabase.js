require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Thieu SUPABASE_URL hoac SUPABASE_ANON_KEY trong file .env');
}

const publicClient = createClient(supabaseUrl, supabaseAnonKey);

const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const adminClient = serviceRoleKey ? createClient(supabaseUrl, serviceRoleKey) : null;

const PRODUCT_IMAGE_BUCKET = 'product-images';

if (adminClient) {
  adminClient.storage.createBucket(PRODUCT_IMAGE_BUCKET, { public: true }).catch(() => {});
}

function clientForUser(accessToken) {
  if (!accessToken) return publicClient;
  return createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
}

module.exports = { publicClient, clientForUser, adminClient, PRODUCT_IMAGE_BUCKET };
