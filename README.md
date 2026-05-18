## MoMo XML Analytics Dashboard
# TEAM NAME : The Stars

An enterprise-level fullstack application for processing, cleaning, categorizing, and visualizing MoMo SMS XML transaction data.

## PROJECT DESCRIPTION:

Design and develop an enterprise-level fullstack application where we process MoMo SMS data in XML format, clean and categorize the data, store it in a relational database, and build a frontend interface to analyze and visualize the data.


## MEMBERS:
    1. Joseph Marube
    2. Philip Mbogho
    3. Davine Uwase

## System Architecture Diagram
https://github.com/josephmarube/the_stars/blob/main/system_architecture.png 

## Database Design

The project uses **MySQL** (not SQLite — see `database/database_setup.sql`).

### Tables
| Table | Purpose |
|---|---|
| `transaction_categories` | Lookup table for 6 MoMo transaction types |
| `users` | Customers, merchants, and agents |
| `transactions` | Core transaction record per SMS |
| `transaction_participants` | Junction table resolving M:N between users and transactions |
| `system_logs` | ETL audit trail — one row per parse/load event |

### Repository structure
- `docs/erd_diagram.png` — Entity relationship diagram
- `docs/erd_rationale.md` — Design justification
- `database/database_setup.sql` — Full DDL + sample data
- `examples/json_schemas.json` — JSON schemas for all 5 entities
- `examples/sql_to_json_mapping.md` — How SQL tables map to JSON API responses

### Run the database
```bash
mysql -u root -p < database/database_setup.sql
```

 ## Objectives

- Parse MoMo XML SMS data
- Clean and normalize transaction records
- Categorize transactions automatically
- Store processed data in SQLite
- Export analytics-ready JSON
- Visualize data on a dashboard

 ## Technologies Used

- Python
- SQLite
- HTML
- CSS
- JavaScript
- FastAPI (Optional)
- Git & GitHub

## Scrum Board

https://trello.com/b/fxmhWKpf/momo-xml-analytics 

## Setup Instructions

### Clone Repository

```bash
git clone https://github.com/josephmarube/the_stars.git
```

### Move Into Project

```bash
cd the_stars
```

### Open in VS Code

```bash
code .
```
