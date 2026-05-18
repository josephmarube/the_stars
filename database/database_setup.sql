DROP DATABASE IF EXISTS momo_sms;

CREATE DATABASE momo_sms
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE momo_sms;

CREATE TABLE transaction_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY
        COMMENT 'Unique identifier for each transaction category',
    name VARCHAR(100) NOT NULL UNIQUE
        COMMENT 'Category label e.g. Send Money, Pay Bill, Airtime Purchase',
    description VARCHAR(255) DEFAULT NULL
        COMMENT 'Human-readable explanation of what this category covers',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Timestamp when this category record was created'
) COMMENT = 'Lookup table classifying all MoMo transaction types';


CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY
        COMMENT 'Unique identifier for each registered MoMo user',
    phone_number VARCHAR(20) NOT NULL UNIQUE
        COMMENT 'E.164 formatted phone number e.g. +250781234567',
    full_name VARCHAR(150) NOT NULL
        COMMENT 'Full registered name of the account holder',
    is_merchant TINYINT(1) NOT NULL DEFAULT 0
        COMMENT '0 = personal account, 1 = merchant or agent business account',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Timestamp when this user account was registered',

    CONSTRAINT chk_phone
        CHECK (phone_number LIKE '+%'),

    CONSTRAINT chk_is_merchant
        CHECK (is_merchant IN (0,1))
) COMMENT = 'All MoMo registered users including customers, merchants, and agents';


CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY
        COMMENT 'Unique identifier for each transaction record',
    ref_code VARCHAR(50) NOT NULL UNIQUE
        COMMENT 'System-generated 10-character alphanumeric MoMo reference code from SMS',
    amount DECIMAL(15,2) NOT NULL
        COMMENT 'Transaction amount in RWF — must be greater than zero',
    fee DECIMAL(10,2) NOT NULL DEFAULT 0.00
        COMMENT 'Transaction fee charged in RWF — zero for categories with no fee',
    sender_id INT DEFAULT NULL
        COMMENT 'FK to users — the account that initiated the transaction, NULL for bank deposits',
    category_id INT DEFAULT NULL
        COMMENT 'FK to transaction_categories — classifies the type of MoMo transaction',
    status VARCHAR(20) NOT NULL DEFAULT 'completed'
        COMMENT 'Transaction lifecycle state: pending | completed | failed',
    transaction_at DATETIME NOT NULL
        COMMENT 'Date and time the transaction occurred as parsed from the SMS',

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
) COMMENT = 'Core MoMo transaction records parsed from SMS data';


CREATE TABLE transaction_participants (
    participant_id INT AUTO_INCREMENT PRIMARY KEY
        COMMENT 'Surrogate primary key for each participation record',
    transaction_id INT NOT NULL
        COMMENT 'FK to transactions — the transaction this participant belongs to',
    user_id INT NOT NULL
        COMMENT 'FK to users — the user participating in this transaction',
    role VARCHAR(20) NOT NULL
        COMMENT 'Role of this user in the transaction: sender | receiver',

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
) COMMENT = 'Junction table resolving the M:N relationship between transactions and users';


CREATE TABLE system_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY
        COMMENT 'Unique identifier for each log entry',
    transaction_id INT DEFAULT NULL
        COMMENT 'FK to transactions — NULL if error occurred before transaction was saved',
    event_type VARCHAR(50) NOT NULL
        COMMENT 'Event class: parse_success | parse_error | load_success | load_error | duplicate | validation_error',
    message TEXT DEFAULT NULL
        COMMENT 'Detailed log message describing the event or error',
    logged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Timestamp when this log event was recorded by the ETL pipeline',

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
) COMMENT = 'ETL audit trail recording all SMS data processing events';

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



-- -----------------------------------------------------------------------------
-- 1. transaction_categories
-- Each maps to a real MTN MoMo transaction type observed in production SMS
-- -----------------------------------------------------------------------------
INSERT INTO transaction_categories (name, description) VALUES
('Incoming Money',     'Money received from another MoMo user into the wallet'),
('Payment to Code',    'Payment made to a merchant or business via merchant code'),
('Transfer to Mobile', 'Peer to peer RWF transfer sent to another mobile number'),
('Bank Deposit',       'Cash deposited into MoMo wallet from a bank or agent'),
('Airtime Purchase',   'Mobile airtime top-up purchased for self or third party'),
('Agent Withdrawal',   'Cash withdrawn from MoMo wallet at a registered agent');


-- -----------------------------------------------------------------------------
-- 2. users
-- users covering all real MoMo network participant types: customers, merchants, and agents 
-- -----------------------------------------------------------------------------
INSERT INTO users (phone_number, full_name, is_merchant) VALUES
('+250780000001', 'Alice Mukamana',     0),
('+250780000002', 'Bob Nkurunziza',     0),
('+250780000003', 'Grace Uwimana',      0),
('+250780000004', 'Jean Paul Habimana', 0),
('+250780000005', 'Kigali MoMo Agent',  1),
('+250780000006', 'SuperMart Kigali',   1),
('+250780000007', 'Rwanda Water WASAC', 1);


-- -----------------------------------------------------------------------------
-- 3. transactions
-- ref codes are 10-character alphanumeric system-generated identifiers
-- sender_id NULL on bank deposit: SMS format carries no human sender field
-- failed transaction reflects real insufficient balance scenario
-- -----------------------------------------------------------------------------
INSERT INTO transactions (ref_code, amount, fee, sender_id, category_id, status, transaction_at) VALUES
('B7K3X9P2QA', 25000.00,   0.00, 2,    1, 'completed', '2024-05-01 08:14:22'),
('M1R8T4W6NZ',  5000.00,   0.00, 1,    2, 'completed', '2024-05-02 10:01:45'),
('H5C2L9F7YD', 10000.00, 100.00, 1,    3, 'completed', '2024-05-03 17:30:10'),
('Q4V6J1K8XR', 20000.00,   0.00, NULL, 4, 'completed', '2024-05-04 09:00:00'),
('N3G7W2B5TM',  1000.00,   0.00, 1,    5, 'completed', '2024-05-04 11:45:33'),
('Z9P1Y4C8HQ', 15000.00, 200.00, 1,    6, 'completed', '2024-05-05 12:22:08'),
('D6F3R7V2KL',  8000.00, 100.00, 1,    3, 'failed',    '2024-05-05 14:10:55');


-- -----------------------------------------------------------------------------
-- 4. transaction_participants
-- bank deposit (Q4V6J1K8XR) has receiver only — no human sender in SMS format
-- airtime (N3G7W2B5TM) has sender only — recipient is MTN system, not a user
-- failed transaction (D6F3R7V2KL) still records both participants
-- -----------------------------------------------------------------------------
INSERT INTO transaction_participants (transaction_id, user_id, role) VALUES
(1, 2, 'sender'),
(1, 1, 'receiver'),
(2, 1, 'sender'),
(2, 6, 'receiver'),
(3, 1, 'sender'),
(3, 3, 'receiver'),
(4, 1, 'receiver'),
(5, 1, 'sender'),
(6, 1, 'sender'),
(6, 5, 'receiver'),
(7, 1, 'sender'),
(7, 4, 'receiver');


-- -----------------------------------------------------------------------------
-- 5. system_logs
-- log format: ref | category | amount | sender -> receiver
-- reflects real pipeline behaviour: parse, load, error, duplicate detection
-- NULL transaction_id on parse_error and duplicate: no transaction was created
-- -----------------------------------------------------------------------------
INSERT INTO system_logs (transaction_id, event_type, message) VALUES
(1,    'parse_success', 'B7K3X9P2QA | incoming_money | 25000 RWF | +250780000002 -> +250780000001'),
(1,    'load_success',  'B7K3X9P2QA committed to transactions [row_id=1]'),
(2,    'parse_success', 'M1R8T4W6NZ | payment_to_code | 5000 RWF | +250780000001 -> +250780000006'),
(3,    'parse_success', 'H5C2L9F7YD | transfer_to_mobile | 10000 RWF + 100 fee | +250780000001 -> +250780000003'),
(4,    'parse_success', 'Q4V6J1K8XR | bank_deposit | 20000 RWF | system -> +250780000001'),
(4,    'load_success',  'Q4V6J1K8XR committed to transactions [row_id=4]'),
(5,    'parse_success', 'N3G7W2B5TM | airtime | 1000 RWF | +250780000001 -> MTN'),
(7,    'parse_success', 'D6F3R7V2KL | transfer_to_mobile | 8000 RWF + 100 fee | +250780000001 -> +250780000004'),
(7,    'load_error',    'D6F3R7V2KL status=failed | balance 5600 RWF insufficient for 8100 RWF debit'),
(NULL, 'parse_error',   'offset 4821 | regex match failed | body="*161*..." unrecognised pattern'),
(NULL, 'duplicate',     'H5C2L9F7YD rejected | ref already exists in transactions [row_id=3]');
