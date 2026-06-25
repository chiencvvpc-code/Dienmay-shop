const express = require('express');
const { publicClient, clientForUser } = require('../db/supabase');

const router = express.Router();

router.get('/register', (req, res) => {
  res.render('register', { error: null });
});

router.post('/register', async (req, res) => {
  const { name, email, password, confirmPassword } = req.body;

  if (!name || !email || !password) {
    return res.render('register', { error: 'Vui long dien day du thong tin' });
  }
  if (password !== confirmPassword) {
    return res.render('register', { error: 'Mat khau xac nhan khong khop' });
  }
  if (password.length < 6) {
    return res.render('register', { error: 'Mat khau phai co it nhat 6 ky tu' });
  }

  const { data, error } = await publicClient.auth.signUp({ email, password });

  if (error) {
    return res.render('register', { error: error.message });
  }

  if (data.session) {
    const userClient = clientForUser(data.session.access_token);
    await userClient.from('profiles').insert({ id: data.user.id, name });
    res.redirect('/login');
  } else {
    res.render('login', {
      error: 'Đăng ký thành công! Vui lòng kiểm tra email để xác nhận trước khi đăng nhập.',
    });
  }
});

router.get('/login', (req, res) => {
  res.render('login', { error: null });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const { data, error } = await publicClient.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    return res.render('login', { error: 'Email hoặc mật khẩu không đúng' });
  }

  const userClient = clientForUser(data.session.access_token);
  let { data: profile } = await userClient
    .from('profiles')
    .select('*')
    .eq('id', data.user.id)
    .single();

  if (!profile) {
    await userClient.from('profiles').insert({ id: data.user.id, name: email.split('@')[0] });
    profile = { name: email.split('@')[0], is_admin: false };
  }

  req.session.user = {
    id: data.user.id,
    email: data.user.email,
    name: profile.name,
    is_admin: !!profile.is_admin,
    access_token: data.session.access_token,
  };

  res.redirect('/');
});

router.post('/logout', (req, res) => {
  req.session = null;
  res.redirect('/');
});

module.exports = router;
