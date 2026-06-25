-- Chay doan nay trong Supabase SQL Editor

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  is_admin boolean not null default false,
  created_at timestamptz default now()
);

create table if not exists categories (
  id bigint generated always as identity primary key,
  name text not null,
  slug text unique not null,
  icon text
);

create table if not exists products (
  id bigint generated always as identity primary key,
  category_id bigint not null references categories(id),
  name text not null,
  brand text,
  description text,
  specs jsonb default '{}',
  price numeric not null,
  original_price numeric,
  image text,
  stock integer not null default 0,
  created_at timestamptz default now()
);

create table if not exists orders (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id),
  total numeric not null,
  status text not null default 'pending',
  created_at timestamptz default now()
);

create table if not exists order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references orders(id),
  product_id bigint not null references products(id),
  quantity integer not null,
  price numeric not null
);

-- Bat Row Level Security
alter table profiles enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table categories enable row level security;
alter table products enable row level security;

-- Categories/Products: ai cung doc duoc
create policy "public read categories" on categories for select using (true);
create policy "public read products" on products for select using (true);

-- Profiles: user chi xem/sua chinh minh
create policy "user read own profile" on profiles for select using (auth.uid() = id);
create policy "user insert own profile" on profiles for insert with check (auth.uid() = id);

-- Orders: user chi xem don hang cua minh
create policy "user read own orders" on orders for select using (auth.uid() = user_id);
create policy "user insert own orders" on orders for insert with check (auth.uid() = user_id);
create policy "user read own order_items" on order_items for select using (
  exists (select 1 from orders where orders.id = order_items.order_id and orders.user_id = auth.uid())
);
create policy "user insert own order_items" on order_items for insert with check (
  exists (select 1 from orders where orders.id = order_items.order_id and orders.user_id = auth.uid())
);

-- Seed du lieu danh muc va san pham
insert into categories (name, slug, icon) values
  ('Tivi', 'tivi', '📺'),
  ('Tủ lạnh', 'tu-lanh', '🧊'),
  ('Máy giặt', 'may-giat', '🧺'),
  ('Điều hòa', 'dieu-hoa', '❄️'),
  ('Điện thoại', 'dien-thoai', '📱'),
  ('Laptop', 'laptop', '💻')
on conflict (slug) do nothing;

insert into products (category_id, name, brand, description, specs, price, original_price, image, stock)
select c.id, p.name, p.brand, p.description, p.specs::jsonb, p.price, p.original_price, p.image, p.stock
from (values
  ('tivi', 'Smart Tivi Samsung 50 inch UA50CU7000', 'Samsung', 'Tivi Samsung Crystal UHD 4K, hệ điều hành Tizen, hỗ trợ Google Assistant.', '{"Màn hình":"50 inch, 4K UHD","Hệ điều hành":"Tizen OS","Kết nối":"Wifi, Bluetooth, 3x HDMI","Bảo hành":"24 tháng"}', 8490000, 10990000, '/img/products/tivi.svg', 25),
  ('tivi', 'Smart Tivi LG 43 inch 43UQ7550', 'LG', 'Tivi LG UHD 4K với webOS 22, hình ảnh sắc nét, âm thanh sống động.', '{"Màn hình":"43 inch, 4K UHD","Hệ điều hành":"webOS 22","Kết nối":"Wifi, Bluetooth, 3x HDMI","Bảo hành":"24 tháng"}', 6290000, 7990000, '/img/products/tivi.svg', 30),
  ('tivi', 'Google Tivi Sony 55 inch KD-55X75K', 'Sony', 'Tivi Sony 4K HDR, chip xử lý X1, Google TV, âm thanh Dolby Atmos.', '{"Màn hình":"55 inch, 4K HDR","Hệ điều hành":"Google TV","Âm thanh":"Dolby Atmos","Bảo hành":"24 tháng"}', 12990000, 15990000, '/img/products/tivi.svg', 15),
  ('tivi', 'Smart Tivi TCL 32 inch 32S5400', 'TCL', 'Tivi TCL HD, Android TV, phù hợp phòng ngủ, phòng nhỏ.', '{"Màn hình":"32 inch, HD","Hệ điều hành":"Android TV","Kết nối":"Wifi, 2x HDMI","Bảo hành":"24 tháng"}', 3290000, 4290000, '/img/products/tivi.svg', 40),
  ('tivi', 'Smart Tivi Samsung 65 inch QLED QA65Q70C', 'Samsung', 'Tivi QLED cao cấp, màu sắc rực rỡ, Quantum HDR.', '{"Màn hình":"65 inch, QLED 4K","Hệ điều hành":"Tizen OS","Tần số quét":"120Hz","Bảo hành":"24 tháng"}', 18990000, 23990000, '/img/products/tivi.svg', 10),
  ('tivi', 'Smart Tivi Casper 40 inch 40FG5200', 'Casper', 'Tivi giá rẻ, chất lượng ổn, phù hợp gia đình.', '{"Màn hình":"40 inch, Full HD","Hệ điều hành":"Android TV","Kết nối":"Wifi, 2x HDMI","Bảo hành":"24 tháng"}', 3890000, 4990000, '/img/products/tivi.svg', 35),

  ('tu-lanh', 'Tủ lạnh Samsung Inverter 236L RT22M4032BU', 'Samsung', 'Tủ lạnh 2 cánh, công nghệ làm lạnh đa chiều, tiết kiệm điện.', '{"Dung tích":"236 lít","Loại":"2 cánh","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 6190000, 7490000, '/img/products/tu-lanh.svg', 20),
  ('tu-lanh', 'Tủ lạnh LG Inverter 374L GN-D372PS', 'LG', 'Tủ lạnh ngăn đá dưới, công nghệ Door Cooling+, tiết kiệm điện.', '{"Dung tích":"374 lít","Loại":"Ngăn đá dưới","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 9990000, 11990000, '/img/products/tu-lanh.svg', 18),
  ('tu-lanh', 'Tủ lạnh Toshiba Inverter 180L GR-B22VU', 'Toshiba', 'Tủ lạnh nhỏ gọn, phù hợp gia đình ít người.', '{"Dung tích":"180 lít","Loại":"2 cánh","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 4490000, 5490000, '/img/products/tu-lanh.svg', 25),
  ('tu-lanh', 'Tủ lạnh Panasonic Inverter 326L NR-TV341', 'Panasonic', 'Công nghệ kháng khuẩn Nanoe X, ngăn rau quả tươi lâu.', '{"Dung tích":"326 lít","Loại":"Ngăn đá dưới","Công nghệ":"Inverter, Nanoe X","Bảo hành":"24 tháng"}', 8290000, 9990000, '/img/products/tu-lanh.svg', 15),
  ('tu-lanh', 'Tủ lạnh Side by Side Samsung 617L RS62R5001M9', 'Samsung', 'Tủ lạnh side by side cao cấp, dung tích lớn, thiết kế sang trọng.', '{"Dung tích":"617 lít","Loại":"Side by Side","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 21990000, 26990000, '/img/products/tu-lanh.svg', 8),
  ('tu-lanh', 'Tủ lạnh Aqua Inverter 212L AQR-T239FA', 'Aqua', 'Tủ lạnh giá tốt, vận hành êm ái, tiết kiệm điện năng.', '{"Dung tích":"212 lít","Loại":"2 cánh","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 4990000, 5990000, '/img/products/tu-lanh.svg', 22),

  ('may-giat', 'Máy giặt Samsung Inverter 9kg WW90T3040', 'Samsung', 'Máy giặt cửa trước, công nghệ Eco Bubble, giặt sạch nhẹ nhàng.', '{"Khối lượng giặt":"9kg","Loại":"Cửa trước","Công nghệ":"Inverter, Eco Bubble","Bảo hành":"24 tháng"}', 6890000, 7990000, '/img/products/may-giat.svg', 20),
  ('may-giat', 'Máy giặt LG Inverter 10kg FV1410S4W', 'LG', 'Công nghệ AI DD nhận diện vải, tiết kiệm nước và điện.', '{"Khối lượng giặt":"10kg","Loại":"Cửa trước","Công nghệ":"AI Direct Drive","Bảo hành":"24 tháng"}', 8990000, 10490000, '/img/products/may-giat.svg', 15),
  ('may-giat', 'Máy giặt Toshiba 8kg AW-J900LV', 'Toshiba', 'Máy giặt cửa trên, giá rẻ, bền bỉ, phù hợp gia đình nhỏ.', '{"Khối lượng giặt":"8kg","Loại":"Cửa trên","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 5290000, 6290000, '/img/products/may-giat.svg', 25),
  ('may-giat', 'Máy giặt Electrolux Inverter 9kg EWF9024D3WB', 'Electrolux', 'Công nghệ UltraMix hòa tan bột giặt trước khi giặt.', '{"Khối lượng giặt":"9kg","Loại":"Cửa trước","Công nghệ":"Inverter, UltraMix","Bảo hành":"24 tháng"}', 7690000, 8990000, '/img/products/may-giat.svg', 18),
  ('may-giat', 'Máy giặt sấy LG Inverter 12kg FV1412G4', 'LG', 'Máy giặt sấy 2 trong 1, tiện lợi cho gia đình bận rộn.', '{"Khối lượng giặt":"12kg/8kg sấy","Loại":"Cửa trước","Công nghệ":"AI Direct Drive","Bảo hành":"24 tháng"}', 14990000, 17990000, '/img/products/may-giat.svg', 10),
  ('may-giat', 'Máy giặt Panasonic 8.5kg NA-F85A9DRV', 'Panasonic', 'Máy giặt cửa trên với công nghệ Active Foam giặt sạch sâu.', '{"Khối lượng giặt":"8.5kg","Loại":"Cửa trên","Công nghệ":"Active Foam","Bảo hành":"24 tháng"}', 5790000, 6790000, '/img/products/may-giat.svg', 20),

  ('dieu-hoa', 'Điều hòa Daikin Inverter 1 chiều 9000BTU', 'Daikin', 'Điều hòa tiết kiệm điện, vận hành êm, làm lạnh nhanh.', '{"Công suất":"9000 BTU","Loại":"1 chiều","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 9990000, 11990000, '/img/products/dieu-hoa.svg', 30),
  ('dieu-hoa', 'Điều hòa Panasonic Inverter 2 chiều 12000BTU', 'Panasonic', 'Điều hòa 2 chiều làm lạnh và sưởi ấm, lọc không khí kháng khuẩn.', '{"Công suất":"12000 BTU","Loại":"2 chiều","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 13990000, 16990000, '/img/products/dieu-hoa.svg', 20),
  ('dieu-hoa', 'Điều hòa Samsung Inverter 1 chiều 9000BTU', 'Samsung', 'Điều hòa giá tốt, làm lạnh nhanh với chế độ Fast Cooling.', '{"Công suất":"9000 BTU","Loại":"1 chiều","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 8490000, 9990000, '/img/products/dieu-hoa.svg', 28),
  ('dieu-hoa', 'Điều hòa LG Inverter 1 chiều 12000BTU', 'LG', 'Công nghệ Dual Inverter tiết kiệm điện vượt trội.', '{"Công suất":"12000 BTU","Loại":"1 chiều","Công nghệ":"Dual Inverter","Bảo hành":"24 tháng"}', 11490000, 13490000, '/img/products/dieu-hoa.svg', 22),
  ('dieu-hoa', 'Điều hòa Casper Inverter 1 chiều 9000BTU', 'Casper', 'Điều hòa giá rẻ, phù hợp phòng nhỏ, vận hành ổn định.', '{"Công suất":"9000 BTU","Loại":"1 chiều","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 6990000, 8290000, '/img/products/dieu-hoa.svg', 35),
  ('dieu-hoa', 'Điều hòa Daikin Inverter 2 chiều 18000BTU', 'Daikin', 'Công suất lớn phù hợp phòng rộng, làm lạnh và sưởi ấm.', '{"Công suất":"18000 BTU","Loại":"2 chiều","Công nghệ":"Inverter","Bảo hành":"24 tháng"}', 19990000, 23990000, '/img/products/dieu-hoa.svg', 12),

  ('dien-thoai', 'iPhone 15 128GB', 'Apple', 'Chip A16 Bionic, camera 48MP, màn hình Dynamic Island.', '{"Màn hình":"6.1 inch OLED","Chip":"A16 Bionic","Camera":"48MP","Bảo hành":"12 tháng"}', 19990000, 22990000, '/img/products/dien-thoai.svg', 30),
  ('dien-thoai', 'Samsung Galaxy S24 256GB', 'Samsung', 'Galaxy AI tích hợp, camera zoom quang học, hiệu năng mạnh mẽ.', '{"Màn hình":"6.2 inch Dynamic AMOLED","Chip":"Snapdragon 8 Gen 3","Camera":"50MP","Bảo hành":"12 tháng"}', 21990000, 24990000, '/img/products/dien-thoai.svg', 25),
  ('dien-thoai', 'Xiaomi Redmi Note 13 128GB', 'Xiaomi', 'Camera 108MP, sạc nhanh 33W, pin 5000mAh.', '{"Màn hình":"6.67 inch AMOLED","Chip":"Snapdragon 685","Camera":"108MP","Bảo hành":"12 tháng"}', 4990000, 5990000, '/img/products/dien-thoai.svg', 50),
  ('dien-thoai', 'OPPO Reno11 256GB', 'OPPO', 'Camera Portrait chuyên nghiệp, thiết kế mỏng nhẹ.', '{"Màn hình":"6.7 inch AMOLED","Chip":"Dimensity 7050","Camera":"50MP","Bảo hành":"12 tháng"}', 9990000, 11990000, '/img/products/dien-thoai.svg', 35),
  ('dien-thoai', 'Samsung Galaxy A55 128GB', 'Samsung', 'Thiết kế khung kim loại, camera chống rung OIS.', '{"Màn hình":"6.6 inch Super AMOLED","Chip":"Exynos 1480","Camera":"50MP","Bảo hành":"12 tháng"}', 8990000, 10490000, '/img/products/dien-thoai.svg', 40),
  ('dien-thoai', 'iPhone 13 128GB', 'Apple', 'Chip A15 Bionic, camera kép, vẫn rất mạnh mẽ và bền bỉ.', '{"Màn hình":"6.1 inch OLED","Chip":"A15 Bionic","Camera":"12MP kép","Bảo hành":"12 tháng"}', 14990000, 17990000, '/img/products/dien-thoai.svg', 28),

  ('laptop', 'Laptop Dell Inspiron 15 3520 i5', 'Dell', 'Core i5 thế hệ 12, RAM 8GB, SSD 512GB, phù hợp văn phòng.', '{"CPU":"Intel Core i5-1235U","RAM":"8GB","Ổ cứng":"SSD 512GB","Bảo hành":"12 tháng"}', 14990000, 17990000, '/img/products/laptop.svg', 20),
  ('laptop', 'Laptop Asus Vivobook 15 OLED A1505VA i5', 'Asus', 'Màn hình OLED sắc nét, hiệu năng tốt cho công việc và giải trí.', '{"CPU":"Intel Core i5-13500H","RAM":"16GB","Ổ cứng":"SSD 512GB","Bảo hành":"24 tháng"}', 16990000, 19990000, '/img/products/laptop.svg', 15),
  ('laptop', 'MacBook Air M2 13 inch 256GB', 'Apple', 'Chip Apple M2, thiết kế mỏng nhẹ, thời lượng pin vượt trội.', '{"CPU":"Apple M2","RAM":"8GB","Ổ cứng":"SSD 256GB","Bảo hành":"12 tháng"}', 24990000, 27990000, '/img/products/laptop.svg', 18),
  ('laptop', 'Laptop Lenovo IdeaPad Slim 5 i7', 'Lenovo', 'Core i7 thế hệ 13, RAM 16GB, hiệu năng mạnh mẽ đa nhiệm.', '{"CPU":"Intel Core i7-13620H","RAM":"16GB","Ổ cứng":"SSD 512GB","Bảo hành":"24 tháng"}', 18990000, 21990000, '/img/products/laptop.svg', 12),
  ('laptop', 'Laptop Gaming Acer Nitro V i5 RTX3050', 'Acer', 'Card đồ họa RTX 3050, chiến game mượt mà, tản nhiệt tốt.', '{"CPU":"Intel Core i5-13420H","GPU":"RTX 3050 6GB","RAM":"16GB","Bảo hành":"24 tháng"}', 22990000, 25990000, '/img/products/laptop.svg', 10),
  ('laptop', 'Laptop HP 15 fc0xxx Ryzen 5', 'HP', 'AMD Ryzen 5, giá tốt, phù hợp học tập và làm việc cơ bản.', '{"CPU":"AMD Ryzen 5 7430U","RAM":"8GB","Ổ cứng":"SSD 512GB","Bảo hành":"12 tháng"}', 12990000, 15490000, '/img/products/laptop.svg', 22)
) as p(category_slug, name, brand, description, specs, price, original_price, image, stock)
join categories c on c.slug = p.category_slug;
