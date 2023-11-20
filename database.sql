-- USERS
-- Note: This table contains user data. Users should only be able to view and update their own data.
CREATE TABLE users (
  id CHAR(36) PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  billing_address JSON,
  payment_method JSON
);

-- This trigger automatically creates a user entry when a new user signs up via Supabase Auth.
DELIMITER //
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW
BEGIN
  INSERT INTO users (id, full_name, avatar_url)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url');
END;
//
DELIMITER ;

-- CUSTOMERS
-- Note: this is a private table that contains a mapping of user IDs to Strip customer IDs.
CREATE TABLE customers (
  id CHAR(36) PRIMARY KEY,
  stripe_customer_id TEXT
);

-- PRODUCTS
-- Note: products are created and managed in Stripe and synced to our DB via Stripe webhooks.
CREATE TABLE products (
  id VARCHAR(255) PRIMARY KEY,
  active BOOLEAN,
  name TEXT,
  description TEXT,
  image TEXT,
  metadata JSON
);

-- PRICES
-- Note: prices are created and managed in Stripe and synced to our DB via Stripe webhooks.
CREATE TABLE prices (
  id VARCHAR(255) PRIMARY KEY,
  product_id VARCHAR(255) REFERENCES products(id),
  active BOOLEAN,
  description TEXT,
  unit_amount BIGINT,
  currency CHAR(3) CHECK (CHAR_LENGTH(currency) = 3),
  pricing_type ENUM ('one_time', 'recurring'),
  interval ENUM ('day', 'week', 'month', 'year'),
  interval_count INT,
  trial_period_days INT,
  metadata JSON
);

-- SUBSCRIPTIONS
-- Note: subscriptions are created and managed in Stripe and synced to our DB via Stripe webhooks.
CREATE TABLE subscriptions (
  id VARCHAR(255) PRIMARY KEY,
  user_id CHAR(36) REFERENCES users(id),
  status ENUM ('trialing', 'active', 'canceled', 'incomplete', 'incomplete_expired', 'past_due', 'unpaid'),
  metadata JSON,
  price_id VARCHAR(255) REFERENCES prices(id),
  quantity INT,
  cancel_at_period_end BOOLEAN,
  created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  current_period_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  current_period_end TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP,
  cancel_at TIMESTAMP,
  canceled_at TIMESTAMP,
  trial_start TIMESTAMP,
  trial_end TIMESTAMP
);

-- REALTIME SUBSCRIPTIONS
-- Only allow realtime listening on public tables.
-- Note: MySQL doesn't have direct support for PostgreSQL publications and subscriptions.
-- Real-time functionality might need to be implemented using other mechanisms.
