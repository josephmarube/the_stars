# AI Usage Log 

## Assignment 1: Database Design And Implementation

## Person 1 : Davine Uwase 

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

- Used for a grammar and spelling check on erd_rationale.md. 
  All technical content and reasoning in that document was written 
  independently.

## Person 2 : Joseph Marube 

- Used to confirm that NULL is valid MySQL syntax for an optional 
  foreign key column in an INSERT statement. 
  The decision that bank deposit transactions carry no human sender 
  was made independently after analysing the XML SMS body format, 
  which contains no sender phone number for that transaction type.

- Used to confirm the correct terminal command for running a SQL 
  file from WSL: sudo mysql < database/database_setup.sql. 
  No schema or logic decisions were involved.

## Person 3 : Philip Mbogho 

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

- Used for a spelling and grammar check on sql_to_json_mapping.md 
  and README.md. All technical content was written independently.

  ## Assignment Two: Building And Securing a REST API

  ## Person 1 : Joseph Marube

  ## Person 2 : Philip Mbogho

- Used Claude to diagnose ModuleNotFoundError (running from wrong directory).

- Used Claude to inspect *162* XML body patterns. Fix to catch Bundles and 
  ONAFRIQ variants decided independently after reading the actual XML output.

- Category logic, ID assignment strategy, and skip policy for OTPs decided 
  independently
  
- Used Claude to identify syntax error (missing triple quote) and three 
  indentation errors introduced during manual editing.

- TX_INDEX design decision (dict over list for O(1) lookup) made 
  independently, connecting to the team's DSA analysis.
/health endpoint structure decided independently.

- Used Claude to confirm dict.pop() syntax for safe deletion without KeyError.


  ## Person 3 : Davine Uwase 
  
  ## Claude
- Used to clarify the difference between linear search O(n) and dictionary lookup O(1) in Python dictionaries.
The actual implementation, timing measurements, and comparison logic in dsa/search_compare.py were written and tested independently. 

- Used to research why dictionary lookups are generally faster than linear search and to understand possible alternatives such as binary search trees and hash-based structures.
The final reflection and analysis were written independently based on the measured results from the project dataset.

- Used to review the required structure for REST API documentation and understand standard formatting for endpoint descriptions, request examples, response examples, and error codes.
All endpoint documentation in docs/api_docs.md was written independently using the team’s actual API implementation and test results.

- Used to refine wording and improve clarity in explanations related to Basic Authentication limitations, JWT, and OAuth2 for the project report.
The final explanations and recommendations were reviewed and edited independently before submission.

## Grammarly

- Used for grammar and spelling checks in api_docs.md and the written DSA reflection sections.
All technical explanations and documentation content were written independently.