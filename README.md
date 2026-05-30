## MoMo XML Analytics Dashboard
# TEAM NAME : The Stars

An enterprise-level fullstack application for processing, cleaning, categorizing, and visualizing MoMo SMS XML transaction data.

## Team:
    1. Joseph Marube
    2. Philip Mbogho
    3. Davine Uwase

**Scrum Board:** https://github.com/users/duwase7/projects/1

## PROJECT DESCRIPTION:

Design and develop an enterprise-level fullstack application where we process MoMo SMS data in XML format, clean and categorize the data, store it in a relational database, and build a frontend interface to analyze and visualize the data.

 ## Objectives

- Parse MoMo XML SMS data
- Clean and normalize transaction records
- Categorize transactions automatically
- Store processed data in MYSQL
- Export analytics-ready JSON
- Visualize data on a dashboard


## System Architecture 
https://github.com/josephmarube/the_stars/blob/main/system_architecture.png 


### Repository structure
- `docs/erd_diagram.png` — Entity relationship diagram
- `docs/erd_rationale.md` — Design justification
- `database/database_setup.sql` — Full DDL + sample data
- `examples/json_schemas.json` — JSON schemas for all 5 entities
- `examples/sql_to_json_mapping.md` — How SQL tables map to JSON API responses


## Database 

The project uses **MySQL** (not SQLite — see `database/database_setup.sql`).

| Table | Purpose |
|---|---|
| `transaction_categories` | Lookup table for 6 MoMo transaction types |
| `users` | Customers, merchants, and agents |
| `transactions` | Core transaction record per SMS |
| `transaction_participants` | Junction table resolving M:N between users and transactions |
| `system_logs` | ETL audit trail — one row per parse/load event |

```bash
mysql -u root -p < database/database_setup.sql
```


## REST API

Built using Python's built-in `http.server` — no external frameworks.

### Prerequisites

- Python 3.8+
- No pip installs required

### Setup

```bash
git clone https://github.com/josephmarube/the_stars.git
cd the_stars
```

Place the dataset at `data/raw/modified_sms_v2.xml`, then start the server:

```bash
python api/api.py
```

```
  MoMo SMS API running on http://localhost:8080
  Transactions loaded: 1691
  Credentials: admin / password123
```

### Authentication

All endpoints require HTTP Basic Authentication.

```bash
curl -u admin:password123 http://localhost:8080/transactions
```

Missing or wrong credentials return `401 Unauthorized`.

### Endpoints

| Method | Route | Description | Success |
|---|---|---|---|
| GET | `/transactions` | Return all transaction records | 200 |
| GET | `/transactions/{id}` | Return one record by ID | 200 |
| POST | `/transactions` | Create a new transaction | 201 |
| PUT | `/transactions/{id}` | Update an existing transaction | 200 |
| DELETE | `/transactions/{id}` | Delete a transaction | 200 |

Full documentation with request/response examples and error codes: [`docs/api_docs.md`](docs/api_docs.md)

### curl Test Commands

```bash
# List all transactions
curl -u admin:password123 http://localhost:8080/transactions

# Get one transaction
curl -u admin:password123 http://localhost:8080/transactions/1

# Test 401 — wrong credentials
curl -u admin:wrongpassword http://localhost:8080/transactions

# Create a transaction
curl -u admin:password123 -X POST http://localhost:8080/transactions \
     -H "Content-Type: application/json" \
     -d '{"type":"Incoming Money","amount":5000,"sender":"Alice","receiver":"0788000000"}'

# Update a transaction
curl -u admin:password123 -X PUT http://localhost:8080/transactions/1 \
     -H "Content-Type: application/json" \
     -d '{"amount":9999}'

# Delete a transaction
curl -u admin:password123 -X DELETE http://localhost:8080/transactions/1
```

---

## DSA Comparison

```bash
python dsa/search_compare.py
```

Runs linear search O(n) against dictionary lookup O(1) on 20 randomly selected records from the full dataset and prints average timing for both methods.

---

## Technologies

- Python 3 — standard library only
- MySQL 8.0+
- HTML
- CSS
- JavaScript
- FastAPI (Optional)
- Git & GitHub

---

## Notes

- API data is held **in memory** — changes do not persist across server restarts
- Basic Auth is implemented as required by the assignment; JWT would be the production replacement
