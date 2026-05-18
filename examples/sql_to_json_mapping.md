# SQL to JSON Mapping

## How each SQL table maps to JSON

Each table in the database becomes one JSON object when the API sends data back.

| SQL Table                  | JSON key                  | Notes                                       |
|----------------------------|---------------------------|---------------------------------------------|
| transaction_categories     | "transaction_category"    | All columns shown as key-value pairs        |
| users                      | "user"                    | is_merchant: TINYINT(1) becomes true/false  |
| transactions               | "transaction"             | sender_id FK kept as a number               |
| transaction_participants   | "transaction_participant" | role is either sender or receiver           |
| system_logs                | "system_log"              | logged_at stored as a date-time string      |

## How the complex transaction object is built

The complex_transaction object joins data from several tables.
This is what an API would return when a frontend asks for full transaction details.

Step 1 — Get the transaction, its category, and the sender:

```sql
SELECT
  t.transaction_id, t.ref_code, t.amount, t.fee,
  t.status, t.transaction_at,
  c.name AS category_name,
  u.full_name AS sender_name,
  u.phone_number AS sender_phone
FROM transactions t
LEFT JOIN transaction_categories c ON t.category_id = c.category_id
LEFT JOIN users u ON t.sender_id = u.user_id
WHERE t.transaction_id = 3;
```

Step 2 — Get the participants (sender and receiver) for that transaction:

```sql
SELECT tp.participant_id, tp.role,
       u.user_id, u.full_name, u.phone_number
FROM transaction_participants tp
JOIN users u ON tp.user_id = u.user_id
WHERE tp.transaction_id = 3;
```

Step 3 — Get the log entries for that transaction:

```sql
SELECT log_id, event_type, message, logged_at
FROM system_logs
WHERE transaction_id = 3;
```

The results of these three queries are combined in code to produce the nested JSON object.

## Data type changes from SQL to JSON

| SQL type        | JSON type | Example                       |
|-----------------|-----------|-------------------------------|
| INT             | number    | 3                             |
| DECIMAL(15,2)   | number    | 10000.00                      |
| VARCHAR         | string    | "completed"                   |
| DATETIME        | string    | "2024-05-03T17:30:10Z"        |
| TINYINT(1)      | boolean   | false                         |
| NULL            | null      | null                          |

## Transaction categories in the database

The database has 6 categories. Each one matches a type of SMS found in the XML file.

| category_id | name               | SMS pattern in XML                      | Count in XML |
|-------------|--------------------|-----------------------------------------|--------------|
| 1           | Incoming Money     | You have received X RWF from NAME...    | 63           |
| 2           | Payment to Code    | TxId: XXXXX. Your payment of X RWF...  | 660          |
| 3           | Transfer to Mobile | *165*S*X RWF transferred to NAME...    | 585          |
| 4           | Bank Deposit       | *113*R*A bank deposit of X RWF...      | 248          |
| 5           | Airtime Purchase   | *162*TxId:XXXXX*S*Your payment...      | 53           |
| 6           | Agent Withdrawal   | You NAME... withdrawn X RWF via agent..| 3            |

Note: 36 merchant debit messages (*164*S*) and 8 one-time password messages
were also found in the XML. The password messages are skipped — the program
writes a log entry with event_type = parse_error and no transaction is saved.
The 36 merchant messages could be added as a 7th category in a later update.

## Why some log entries have transaction_id = NULL

Some SMS messages cannot be turned into a transaction record. For example,
a one-time password message like "Dear Customer, your password is 2476" has
no amount, no sender phone number, and no receiver. The program skips it.

To keep a record that the message was seen, the program still writes a row
to system_logs, but with no transaction_id because no transaction was created.

In SQL:   transaction_id INT DEFAULT NULL
In JSON:  "transaction_id": null

The log_id itself is always a number — it is AUTO_INCREMENT and is never null.
Only transaction_id can be null, when the log is for a skipped or failed message.