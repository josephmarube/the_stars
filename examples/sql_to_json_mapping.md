# SQL to JSON Mapping

This document explains how the data from our MySQL database becomes JSON when the API sends it to the frontend.

## Tables and their JSON keys

Each table in the database gets its own JSON object. Here is the list:

- The transaction_categories table becomes "transaction_category" in JSON
- The users table becomes "user"
- The transactions table becomes "transaction"
- The transaction_participants table becomes "transaction_participant"
- The system_logs table becomes "system_log"

The columns in each table become the keys inside that JSON object.

## How we build the complex transaction JSON

For the complex transaction object, one query is not enough because we need data from many tables. So we run three queries and the program puts the results together.

The first query gets the transaction itself plus the category and the sender. We use LEFT JOIN because the sender can be NULL for bank deposits:

```sql
SELECT
  t.transaction_id, t.ref_code, t.amount, t.fee,
  t.status, t.transaction_at,
  c.name AS category_name,
  u.full_name AS sender_name
FROM transactions t
LEFT JOIN transaction_categories c ON t.category_id = c.category_id
LEFT JOIN users u ON t.sender_id = u.user_id
WHERE t.transaction_id = 3;
```

After that we get the participants. This is what fills the participants array in the JSON:

```sql
SELECT tp.participant_id, tp.role,
       u.user_id, u.full_name, u.phone_number
FROM transaction_participants tp
JOIN users u ON tp.user_id = u.user_id
WHERE tp.transaction_id = 3;
```

And finally we get the logs for the same transaction:

```sql
SELECT log_id, event_type, message, logged_at
FROM system_logs
WHERE transaction_id = 3;
```

The program code takes the rows from all three queries and builds them into one nested JSON object.

## How SQL data types change in JSON

SQL types and JSON types are not the same. This is how we convert them:

- INT stays as a number, for example 3
- DECIMAL(15,2) also stays as a number, for example 10000.00
- VARCHAR becomes a string in quotes, for example "completed"
- DATETIME becomes a string with the date and time, for example "2024-05-03T17:30:10Z"
- TINYINT(1) becomes true or false in JSON
- NULL in SQL becomes null in JSON (without quotes)

## The 6 categories in the database

We have 6 categories in the SQL. They come from looking at the XML file from the assignment. The XML had 1691 SMS messages and we counted how many were of each type:

| Category ID | Name | Count in XML |
|---|---|---|
| 1 | Incoming Money | 63 |
| 2 | Payment to Code | 660 |
| 3 | Transfer to Mobile | 585 |
| 4 | Bank Deposit | 248 |
| 5 | Airtime Purchase | 53 |
| 6 | Agent Withdrawal | 3 |

The XML also had 36 merchant payment messages and 8 OTP messages, but those are not stored in their own categories yet.

## When transaction_id is NULL in system_logs

Some SMS messages cannot become a transaction. For example, OTP messages just say "your password is 2476". There is no amount, no sender, and no receiver in those messages.

When the program sees this kind of message, it does not insert anything into the transactions table. But we still want to know that we saw the message, so the program writes a row to system_logs anyway.

Because no transaction was created, there is no transaction_id to link the log to. So transaction_id is set to NULL. The log_id itself is always a number because it uses AUTO_INCREMENT.

In JSON this looks like:

```json
{
  "log_id": 10,
  "transaction_id": null,
  "event_type": "parse_error",
  "message": "SMS body did not match any known pattern",
  "logged_at": "2024-05-05T15:00:00Z"
}
```

This is why we set transaction_id INT DEFAULT NULL when we created the system_logs table.