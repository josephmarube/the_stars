# SQL → JSON Mapping

## How each SQL table maps to JSON

| SQL Table                  | JSON key              | Notes                                      |
|----------------------------|-----------------------|--------------------------------------------|
| transaction_categories     | "transaction_category"| Flat object, all columns mapped directly   |
| users                      | "user"                | is_merchant: TINYINT(1) → boolean          |
| transactions               | "transaction"         | sender_id FK stays as integer reference    |
| transaction_participants   | "transaction_participant" | role constrained to sender/receiver    |
| system_logs                | "system_log"          | logged_at uses ISO 8601 format             |

## Complex transaction object — JOIN logic

The complex_transaction object is produced by this SQL:

SELECT
  t.transaction_id, t.ref_code, t.amount, t.fee,
  t.status, t.transaction_at,
  c.category_id, c.name AS category_name,
  u.user_id AS sender_id, u.full_name AS sender_name
FROM transactions t
LEFT JOIN transaction_categories c ON t.category_id = c.category_id
LEFT JOIN users u ON t.sender_id = u.user_id
WHERE t.transaction_id = 13;

The participants array comes from:

SELECT tp.participant_id, tp.role,
       u.user_id, u.full_name, u.phone_number
FROM transaction_participants tp
JOIN users u ON tp.user_id = u.user_id
WHERE tp.transaction_id = 13;

The system_logs array comes from:

SELECT log_id, event_type, message, logged_at
FROM system_logs
WHERE transaction_id = 13;

## Data type conversions

- TINYINT(1) is_merchant → JSON boolean (true/false)
- DATETIME → ISO 8601 string ("2024-05-11T18:48:42Z")
- DECIMAL(15,2) → JSON number (10000.00)
- NULL values → JSON null