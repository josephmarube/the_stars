### API Docs
Base URL: http://localhost:8080 Auth: HTTP Basic Auth on all endpoints Dev credentials: admin / password123

## How auth works
Every request needs an Authorization header. The client encodes username:password in base64 and sends it along. With curl you just use -u admin:password123 and it handles that for you.

If you get a 401 back, either the credentials are wrong or you forgot the header entirely.

## GET /transactions
Returns all transactions.

curl -u admin:password123 http://localhost:8080/transactions
Response (200):

[
  {
    "transaction_id": 1,
    "type": "Incoming Money",
    "amount": 5000.0,
    "sender": "Jane Doe",
    "receiver": "self",
    "timestamp": "10 May 2024 4:30:58 PM",
    "ref_code": "76662021700"
  }
]
Returns [] if no transactions exist.

## GET /transactions/{id}
Returns a single transaction by its ID.

curl -u admin:password123 http://localhost:8080/transactions/1
Response (200): same fields as above but a single object.

Response (404):

{
  "error": "Not Found",
  "message": "No transaction with id '999'"
}
## POST /transactions
Adds a new transaction. Required fields: type, amount, sender, receiver.

curl -u admin:password123 -X POST \
  -H "Content-Type: application/json" \
  -d '{"type":"Incoming Money","amount":5000,"sender":"Alice","receiver":"self"}' \
  http://localhost:8080/transactions
Response (201):

{
  "transaction_id": 1611,
  "type": "Incoming Money",
  "amount": 5000,
  "sender": "Alice",
  "receiver": "self",
  "timestamp": "",
  "ref_code": ""
}
The ID is auto-generated. timestamp and ref_code are optional — they default to empty string if not provided.

Response (400) if fields are missing:

{
  "error": "Bad Request",
  "message": "Missing required fields: ['sender']"
}
## PUT /transactions/{id}
Updates fields on an existing transaction. Only send what you want to change.

curl -u admin:password123 -X PUT \
  -H "Content-Type: application/json" \
  -d '{"amount": 9999}' \
  http://localhost:8080/transactions/1
Response (200): returns the full updated record.

Response (404) if the ID doesn't exist.

## DELETE /transactions/{id}
Deletes a transaction and returns what was deleted.

curl -u admin:password123 -X DELETE http://localhost:8080/transactions/1
Response (200):

{
  "message": "Transaction 1 deleted successfully",
  "deleted": {
    "transaction_id": 1,
    "type": "Incoming Money",
    "amount": 5000.0,
    "sender": "Jane Doe",
    "receiver": "self",
    "timestamp": "10 May 2024 4:30:58 PM",
    "ref_code": "76662021700"
  }
}
After deleting, a GET on the same ID should come back 404.

Error codes
Code	When
200	success
201	new transaction created
400	missing fields or bad JSON
401	wrong or missing credentials
404	transaction not found
500	something broke on the server

## Security
Basic auth has some obvious problems. Credentials go out with every request, base64 is not encryption so anyone intercepting traffic can decode them immediately, and there's no expiry so stolen credentials stay valid forever. There's also no way to give different users different levels of access.

JWT would be a straightforward upgrade. You log in once, get back a signed token with an expiry time, and send that instead of your password on every request. When it expires you need to log in again. Works well for an API like this.

OAuth2 is more involved — it handles delegated access so users can grant specific permissions to specific apps without sharing their password. Better suited for something with multiple clients or third-party integrations.

For this project JWT makes the most sense. It fixes the main weaknesses of basic auth without being overly complex to implement.

