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

## Transaction categories discovered from XML analysis

The XML file contains 1,691 SMS messages with 7 distinct transaction types.
Each maps to one row in the `transaction_categories` table:

| category_id | name                | XML body pattern            | Count in XML |
|-------------|---------------------|-----------------------------|--------------|
| 1           | Send Money          | `*165*S*X RWF transferred…` | 585          |
| 2           | Payment             | `TxId: XXXXX. Your payment…`| 660          |
| 3           | Airtime             | `*162*TxId:XXXXX*S*…`       | 53           |
| 4           | Bank Deposit        | `*113*R*A bank deposit…`    | 248          |
| 5           | Receive Money       | `You have received X RWF…`  | 63           |
| 6           | Merchant Payment    | `*164*S*Y'ello, A transaction…` | 36       |
| 7           | Withdrawal          | `You Abebe… withdrawn X RWF via agent…` | 3 |

**Note:** Categories 6 (Merchant Payment) and 7 (Withdrawal) were identified
from the XML analysis and must be added to `database_setup.sql`.

## Unparseable messages — dead-letter handling

8 messages in the XML are one-time password (OTP) notifications:

<#> Dear Customer, your MTN MoMo application one-time password is :2476.

These contain no transaction data. The ETL pipeline does not insert a row
into `transactions` for them. Instead it writes a `system_logs` row with:

- `transaction_id` → NULL  (no linked transaction)
- `event_type`    → `'parse_error'`
- `message`       → a description of why the message was skipped

In JSON this produces:

```json
{
  "log_id": null,
  "transaction_id": null,
  "event_type": "parse_error",
  "message": "OTP SMS skipped — body matched one-time password pattern",
  "logged_at": "2024-05-26T13:17:31Z"
}
```

This is why `system_logs.transaction_id` allows NULL in the SQL schema
(`CONSTRAINT fk_logs_transaction FOREIGN KEY … ON DELETE SET NULL`).
The dead-letter pattern keeps a full audit trail without requiring a
valid transaction record to exist.