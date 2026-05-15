TABLES
I created the transactions table because each SMS represents one mobile money transaction. This table stores the main transaction details such as amount, fee, reference code, and transaction date.

I created the users table to store information about people or businesses using MoMo. This includes names and phone numbers.

The transaction_categories table helps group transactions into categories like Send Money, Pay Bill, or Airtime. This avoids repeating the same category name many times.

I created the transaction_participants table to show which users were involved in each transaction. It also stores their roles, such as sender or receiver.

Finally, I created the system_logs table to keep track of processing events and errors during the ETL process. This helps with monitoring and debugging the system.

RELATIONSHIPS
I connected transaction_categories to transactions because one category can be used for many transactions. However, each transaction belongs to only one category.

I connected users to transactions using sender_id because one user can send many transactions.

I also used the transaction_participants table to solve the many-to-many relationship between users and transactions. One transaction can involve multiple users, and one user can appear in many transactions.

I connected transactions to system_logs because one transaction can have many log records. These logs may include successful processing, duplicate warnings, or validation errors.

CONSTRAINTS
I added CHECK constraints to make sure only valid data is stored in the database. For example, CHECK(amount > 0) prevents negative or zero transaction amounts.

The phone number check ensures numbers follow the correct format.

I used FOREIGN KEY constraints to maintain relationships between tables and ensure linked data is valid. For example, a transaction category must exist before it can be linked to a transaction.

I also used ON DELETE SET NULL in some places to preserve important transaction history even if related records are deleted.