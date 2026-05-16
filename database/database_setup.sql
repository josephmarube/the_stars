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






INSERT INTO transaction_categories (name, description) VALUES
('Send Money',   'Peer-to-peer RWF transfer'),
('Payment',      'Merchant or person payment confirmed via TxId in SMS body'),
('Airtime',      'Mobile airtime top-up'),
('Bank Deposit', 'Cash deposit into MoMo wallet'),
('Receive Money','Incoming transfer from another user');


INSERT INTO users (phone_number, full_name, is_merchant) VALUES
('+250791666666', 'Samuel Carter',  0),
('+250790777777', 'Agent Sophia',  1), 
('+250788999999', 'Robert Brown',   0), 
('+250789888888', 'Linda Green',    0), 
('+250795963036', 'MoMo Agent',     1),  
('+250781000001', 'Alex Doe',       0), 
('+250781000002', 'Jane Smith',     0),
('+250736521838', 'Abebe Chala Chebudie', 0);  

INSERT INTO transactions (ref_code, amount, fee, sender_id, category_id, status, transaction_at) VALUES
-- Payments (TxId format from XML)
('TXN-17818959211',  2000.00,    0.00, 8, 2, 'completed', '2024-05-11 18:48:42'),
('TXN-45434420466', 10900.00,    0.00, 8, 2, 'completed', '2024-05-12 13:26:13'),
('TXN-82113964658',  3500.00,    0.00, 8, 2, 'completed', '2024-05-12 13:34:25'),
('TXN-26614842768',  1000.00,    0.00, 8, 2, 'completed', '2024-05-12 17:58:15'),
('TXN-70497610538',  5000.00,    0.00, 8, 2, 'completed', '2024-05-12 18:08:58'),
('TXN-16913786322',  2150.00,    0.00, 8, 2, 'completed', '2024-05-16 21:35:36'),
('TXN-30173936259',  1500.00,    0.00, 8, 2, 'completed', '2024-05-18 08:15:31'),
('TXN-38084447123',  6000.00,    0.00, 8, 2, 'completed', '2024-05-18 08:48:28'),
('TXN-61189493387',  3500.00,    0.00, 8, 2, 'completed', '2024-05-22 13:44:59'),
('TXN-37467134419',  1800.00,    0.00, 8, 2, 'completed', '2024-05-23 09:51:43'),
('TXN-12131092250',  1000.00,    0.00, 8, 2, 'completed', '2024-05-24 13:10:41'),
('TXN-35617026753',  1500.00,    0.00, 8, 2, 'completed', '2024-05-24 16:41:03'),
-- Send Money transfers (*165*S* format from XML)
('TXN-165-20240511-1', 10000.00, 100.00, 8, 1, 'completed', '2024-05-11 20:34:47'),
('TXN-165-20240512-1',  1000.00,  20.00, 8, 1, 'completed', '2024-05-12 03:47:33'),
('TXN-165-20240512-2',  1700.00, 100.00, 8, 1, 'completed', '2024-05-12 19:23:50'),
('TXN-165-20240512-3',  2000.00, 100.00, 8, 1, 'completed', '2024-05-12 20:49:30'),
('TXN-165-20240514-1',  1800.00, 100.00, 8, 1, 'completed', '2024-05-14 09:11:32'),
('TXN-165-20240514-2',  2500.00, 100.00, 8, 1, 'completed', '2024-05-14 09:27:40'),
('TXN-165-20240514-3',   500.00,  20.00, 8, 1, 'completed', '2024-05-14 14:01:57'),
('TXN-165-20240514-4',  1800.00, 100.00, 8, 1, 'completed', '2024-05-14 19:21:16'),
-- Airtime (*162* format from XML)
('TXN-13913173274',  2000.00,    0.00, 8, 3, 'completed', '2024-05-12 11:41:28'),
-- Receive Money (incoming transfer)
('TXN-45738348638',  1400.00,    0.00, 4, 5, 'completed', '2024-05-19 01:49:09'),
-- Bank Deposits (*113*R* format from XML)
('TXN-DEP-20240514-1', 5000.00,  0.00, NULL, 4, 'completed', '2024-05-14 09:10:29'),
('TXN-DEP-20240514-2', 5000.00,  0.00, NULL, 4, 'completed', '2024-05-14 19:06:03'),
('TXN-DEP-20240518-1', 5000.00,  0.00, NULL, 4, 'completed', '2024-05-18 08:11:36'),
('TXN-DEP-20240518-2', 5000.00,  0.00, NULL, 4, 'completed', '2024-05-18 08:48:00'),
('TXN-DEP-20240521-1', 5000.00,  0.00, NULL, 4, 'completed', '2024-05-21 18:15:06'),
('TXN-DEP-20240524-1', 5000.00,  0.00, NULL, 4, 'completed', '2024-05-24 11:43:17');

INSERT INTO transaction_participants (transaction_id, user_id, role) VALUES
-- Payments: receivers
(1,  1, 'receiver'),
(2,  7, 'receiver'),
(3,  6, 'receiver'),
(4,  3, 'receiver'),
(5,  4, 'receiver'),
(6,  4, 'receiver'),
(7,  3, 'receiver'),
(8,  7, 'receiver'),
(9,  3, 'receiver'),
(10, 3, 'receiver'),
(11, 1, 'receiver'),
(12, 6, 'receiver'),
-- Send Money: receivers
(13, 1, 'receiver'),
(14, 2, 'receiver'),
(15, 3, 'receiver'),
(16, 6, 'receiver'),
(17, 3, 'receiver'),
(18, 7, 'receiver'),
(19, 2, 'receiver'),
(20, 6, 'receiver'),
-- Airtime: receiver
(21, 5, 'receiver'),
-- Receive Money: Abebe received
(22, 8, 'receiver'),
-- Bank Deposits: Abebe received
(23, 8, 'receiver'),
(24, 8, 'receiver'),
(25, 8, 'receiver'),
(26, 8, 'receiver'),
(27, 8, 'receiver'),
(28, 8, 'receiver'),
-- Abebe is sender on all outgoing transactions
(1,  8, 'sender'),
(2,  8, 'sender'),
(3,  8, 'sender'),
(4,  8, 'sender'),
(5,  8, 'sender'),
(6,  8, 'sender'),
(7,  8, 'sender'),
(8,  8, 'sender'),
(9,  8, 'sender'),
(10, 8, 'sender'),
(11, 8, 'sender'),
(12, 8, 'sender'),
(13, 8, 'sender'),
(14, 8, 'sender'),
(15, 8, 'sender'),
(16, 8, 'sender'),
(17, 8, 'sender'),
(18, 8, 'sender'),
(19, 8, 'sender'),
(20, 8, 'sender'),
(21, 8, 'sender'),
(23, 8, 'sender'),
(24, 8, 'sender'),
(25, 8, 'sender'),
(26, 8, 'sender'),
(27, 8, 'sender'),
(28, 8, 'sender'),
-- Linda Green is sender on Receive Money transaction
(22, 4, 'sender');

INSERT INTO system_logs (transaction_id, event_type, message) VALUES
(1,  'parse_success', 'TxId format SMS parsed: TXN-17818959211, amount=2000, fee=0'),
(1,  'load_success',  'Record inserted into transactions table successfully'),
(2,  'parse_success', 'TxId format SMS parsed: TXN-45434420466, amount=10900, fee=0'),
(3,  'parse_success', 'TxId format SMS parsed: TXN-82113964658, amount=3500, fee=0'),
(4,  'parse_success', 'TxId format SMS parsed: TXN-26614842768, amount=1000, fee=0'),
(5,  'parse_success', 'TxId format SMS parsed: TXN-70497610538, amount=5000, fee=0'),
(13, 'parse_success', '*165*S* format SMS parsed: 10000 RWF to Samuel Carter (+250791666666)'),
(13, 'load_success',  'Record inserted into transactions table successfully'),
(14, 'parse_success', '*165*S* format SMS parsed: 1000 RWF to Samuel Carter (+250790777777)'),
(21, 'parse_success', '*162* airtime SMS parsed: TXN-13913173274, amount=2000'),
(22, 'parse_success', 'Receive Money SMS parsed: TXN-45738348638, 1400 RWF from Linda Green'),
(23, 'parse_success', '*113*R* bank deposit SMS parsed: 5000 RWF deposited'),
(23, 'load_success',  'Bank deposit record inserted successfully'),
(24, 'parse_success', '*113*R* bank deposit SMS parsed: 5000 RWF deposited'),
(NULL, 'parse_error', 'SMS body format unrecognised - skipped during ETL batch run'),
(NULL, 'duplicate',   'Duplicate ref_code detected during load - record skipped');


