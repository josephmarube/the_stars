# AI Usage Log — The Stars

## Policy Summary

Permitted: grammar checking, syntax verification, researching best practices
Prohibited: generating ERD designs, SQL schemas, business logic, 
            writing technical explanations or reflections

---

## Person 1 — Davine Uwase (ERD + DDL + Indexes)

**Claude**
- Used to confirm correct MySQL FOREIGN KEY syntax and understand 
  the difference between ON DELETE SET NULL and ON DELETE CASCADE.
  The decision on which tables used SET NULL versus CASCADE was made 
  independently based on personal analysis of the MoMo XML structure.

- Used to research MySQL indexing best practices for financial 
  transaction databases. The guidance was used to understand 
  which column types benefit from indexes. The specific columns 
  chosen to index were decided independently based on our MoMo 
  dashboard query needs.

- Used to verify that CHECK constraint syntax is supported in 
  MySQL 8.0. The actual values being validated — status options, 
  role options, and phone number format — were chosen independently.

- Used to learn how to apply crow's foot notation inside Draw.io. 
  The instructions were used for diagram formatting only. 
  All entities, attributes, and relationships were designed 
  independently before formatting.

**Grammarly**
- Used for a grammar and spelling check on erd_rationale.md. 
  All technical content and reasoning in that document was written 
  independently.

---

## Person 2 — Joseph Marube (INSERT data + CRUD + Screenshots)

**Claude**
- Used to confirm that NULL is valid MySQL syntax for an optional 
  foreign key column in an INSERT statement. 
  The decision that bank deposit transactions carry no human sender 
  was made independently after analysing the XML SMS body format, 
  which contains no sender phone number for that transaction type.

- Used to confirm the correct terminal command for running a SQL 
  file from WSL: sudo mysql < database/database_setup.sql. 
  No schema or logic decisions were involved.

---

## Person 3 — Philip Mbogho (JSON Schemas + Mapping + README)

**Claude**
- Used to understand what a JSON schema looks like for a database 
  entity and how SQL columns map to JSON keys. The MoMo-specific 
  field names and which entities to document were decided 
  independently based on our own five-table schema.

- Used to understand how a nested JSON object represents the result 
  of a SQL JOIN. The specific structure of complex_transaction — 
  which fields to nest, how participants are shown as an array — 
  was decided independently based on our transaction_participants 
  junction table design.

- Used to learn the format for documenting SQL-to-JSON data type 
  conversions. All type mappings were verified independently against 
  our actual CREATE TABLE column definitions.

- Used to analyse the XML file and count SMS messages by pattern 
  type. The counts (660 Payment, 585 Transfer to Mobile, 248 Bank 
  Deposit, 63 Incoming Money, 53 Airtime, 36 Merchant, 3 Withdrawal, 
  8 OTP) were used to justify the 6 categories chosen in the SQL. 
  The category decisions were made independently.

- Used to review json_schemas.json for errors against 
  database_setup.sql. Errors identified included mismatched 
  transaction IDs, wrong category names, and incorrect log IDs. 
  Each correction was made after personally understanding why 
  the mismatch was wrong.

- Used to understand what content belongs in a database design 
  section of a README. The section was written independently 
  using our specific folder names, table names, and project details.

**Grammarly**
- Used for a spelling and grammar check on sql_to_json_mapping.md 
  and README.md. All technical content was written independently.
