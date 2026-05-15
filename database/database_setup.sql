DROP DATABASE IF EXISTS momo_sms;

CREATE DATABASE momo_sms
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE momo_sms;

CREATE TABLE transaction_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    is_merchant TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_phone 
        CHECK (phone_number LIKE '+%'),

    CONSTRAINT chk_is_merchant 
        CHECK (is_merchant IN (0,1))
);

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    ref_code VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(15,2) NOT NULL,
    fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    sender_id INT DEFAULT NULL,
    category_id INT DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
    transaction_at DATETIME NOT NULL,

    CONSTRAINT fk_transactions_sender
        FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_transactions_category
        FOREIGN KEY (category_id)
        REFERENCES transaction_categories(category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_amount
        CHECK (amount > 0),

    CONSTRAINT chk_fee
        CHECK (fee >= 0),

    CONSTRAINT chk_status
        CHECK (status IN ('pending', 'completed', 'failed'))
);

CREATE TABLE transaction_participants (
    participant_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(20) NOT NULL,

    CONSTRAINT uq_participant
        UNIQUE (transaction_id, user_id, role),

    CONSTRAINT fk_tp_transaction
        FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_tp_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_role
        CHECK (role IN ('sender', 'receiver'))
);

CREATE TABLE system_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT DEFAULT NULL,
    event_type VARCHAR(50) NOT NULL,
    message TEXT DEFAULT NULL,
    logged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_logs_transaction
        FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_event_type
        CHECK (
            event_type IN (
                'parse_success',
                'parse_error',
                'load_success',
                'load_error',
                'duplicate',
                'validation_error'
            )
        )
);

CREATE INDEX idx_transactions_date
ON transactions(transaction_at);

CREATE INDEX idx_transactions_status
ON transactions(status);

CREATE INDEX idx_users_phone
ON users(phone_number);

CREATE INDEX idx_logs_event_type
ON system_logs(event_type);

CREATE INDEX idx_logs_logged_at
ON system_logs(logged_at);

CREATE INDEX idx_tp_transaction
ON transaction_participants(transaction_id);

CREATE INDEX idx_tp_user
ON transaction_participants(user_id);
