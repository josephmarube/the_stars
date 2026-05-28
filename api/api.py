"""
Run:   python api/api.py
Test:  curl -u admin:password123 http://localhost:8080/transactions
"""

import json
import base64
import sys
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

# ----- Add project root to path so parse_xml is importable ---------------
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.parse_xml import TRANSACTIONS

# --- Auth credentials --------------------------------
VALID_USER = "admin"
VALID_PASS = "password123"

# -- Port ------------------------------------------
PORT = 8080


# -----------------------------------------------------------------------------
# REQUEST HANDLER
# -----------------------------------------------------------------------------

class MoMoHandler(BaseHTTPRequestHandler):
    """
    Handles all HTTP requests to the MoMo SMS API.

    Auth is checked at the top of every handler method.
    Routing is done by parsing self.path.
    All responses are JSON.
    """

    # ----- Logging (suppress default console noise) --------------------------
    def log_message(self, format, *args):
        print(f"  [{self.command}] {self.path} → {args[1] if len(args) > 1 else ''}")

    # ---------------------------------------------------------------------
    # AUTH MIDDLEWARE
    # ---------------------------------------------------------------------

    def send_401(self):
        """
        Send a 401 Unauthorized response.

        Includes WWW-Authenticate header so the browser/client knows
        this endpoint requires Basic Auth.
        """
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="MoMo API"')
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({
            "error": "Unauthorized",
            "message": "Valid credentials required. Use -u username:password"
        }).encode())

    def check_auth(self):
        """
        Validate HTTP Basic Authentication credentials.

        Returns True if credentials are valid, False otherwise.
        When False, a 401 response has already been sent — the caller
        should return immediately without processing the request.

        How Basic Auth works:
          1. Client sends: Authorization: Basic <base64(user:pass)>
          2. We decode the base64 string → split on ':' → compare
          3. If match → allow; if not → 401
        """
        auth_header = self.headers.get("Authorization", "")

        # Header must start with "Basic " — anything else is rejected
        if not auth_header.startswith("Basic "):
            self.send_401()
            return False

        # Decode: strip "Basic ", base64-decode, split on first ':'
        try:
            encoded = auth_header[6:]                          # remove "Basic "
            decoded = base64.b64decode(encoded).decode("utf-8")
            username, password = decoded.split(":", 1)        # split on first ':'
        except Exception:
            # Malformed header
            self.send_401()
            return False

        # Compare against valid credentials
        if username == VALID_USER and password == VALID_PASS:
            return True

        # Wrong credentials
        self.send_401()
        return False

    # -------------------------------------------------------------------------
    # RESPONSE HELPERS
    # -------------------------------------------------------------------------

    def send_json(self, status, data):
        """Send a JSON response with the given status code."""
        body = json.dumps(data, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_json_body(self):
        """Read and parse the JSON request body. Returns dict or None on error."""
        try:
            length = int(self.headers.get("Content-Length", 0))
            if length == 0:
                return None
            raw = self.rfile.read(length)
            return json.loads(raw.decode("utf-8"))
        except Exception:
            return None

    def parse_id_from_path(self):
        """
        Extract the transaction ID from the URL path.

        /transactions        → returns None
        /transactions/42     → returns "42"
        /transactions/abc123 → returns "abc123"
        """
        path = urlparse(self.path).path.rstrip("/")
        parts = path.split("/")
        # path: ['', 'transactions', '{id}']
        if len(parts) == 3 and parts[2]:
            return parts[2]
        return None

    def find_transaction(self, tx_id):
        """Return (index, transaction) for the given ID, or (None, None)."""
        for i, tx in enumerate(TRANSACTIONS):
            if str(tx.get("transaction_id")) == str(tx_id):
                return i, tx
        return None, None

    def next_id(self):
        """Generate the next transaction ID (max existing + 1)."""
        if not TRANSACTIONS:
            return "1"
        max_id = max(
            int(tx.get("transaction_id", 0))
            for tx in TRANSACTIONS
            if str(tx.get("transaction_id", "0")).isdigit()
        )
        return str(max_id + 1)

    # ---------------------------------------------------------------------
    # ROUTE: GET
    # ---------------------------------------------------------------------

    def do_GET(self):
        """
        GET /transactions          → 200, list all transactions
        GET /transactions/{id}     → 200, single transaction | 404
        """
        # ------- Auth check — must be first ----------------------------------
        if not self.check_auth():
            return

        tx_id = self.parse_id_from_path()

        if tx_id is None:
            # GET /transactions — return full list
            self.send_json(200, TRANSACTIONS)

        else:
            # GET /transactions/{id} — find by ID
            _, tx = self.find_transaction(tx_id)
            if tx is None:
                self.send_json(404, {
                    "error": "Not Found",
                    "message": f"No transaction with id '{tx_id}'"
                })
            else:
                self.send_json(200, tx)

    # ----------------------------------------------------------------------
    # ROUTE: POST
    # ----------------------------------------------------------------------

    def do_POST(self):
        """
        POST /transactions
        Body: JSON object with transaction fields
        → 201, new transaction record with assigned ID
        """
        if not self.check_auth():
            return

        body = self.read_json_body()

        if body is None:
            self.send_json(400, {
                "error": "Bad Request",
                "message": "Request body must be valid JSON"
            })
            return

        # Validate required fields
        required = ["type", "amount", "sender", "receiver"]
        missing = [f for f in required if f not in body]
        if missing:
            self.send_json(400, {
                "error": "Bad Request",
                "message": f"Missing required fields: {missing}"
            })
            return

        # Build new transaction
        new_tx = {
            "transaction_id": self.next_id(),
            "type":           body.get("type"),
            "amount":         body.get("amount"),
            "sender":         body.get("sender"),
            "receiver":       body.get("receiver"),
            "timestamp":      body.get("timestamp", ""),
            "ref_code":       body.get("ref_code", ""),
        }

        TRANSACTIONS.append(new_tx)
        self.send_json(201, new_tx)

    # -----------------------------------------------------------------------
    # ROUTE: PUT
    # -----------------------------------------------------------------------

    def do_PUT(self):
        """
        PUT /transactions/{id}
        Body: JSON object with fields to update
        → 200, updated transaction | 404
        """
        if not self.check_auth():
            return

        tx_id = self.parse_id_from_path()
        if tx_id is None:
            self.send_json(400, {
                "error": "Bad Request",
                "message": "URL must include transaction ID: /transactions/{id}"
            })
            return

        idx, tx = self.find_transaction(tx_id)
        if tx is None:
            self.send_json(404, {
                "error": "Not Found",
                "message": f"No transaction with id '{tx_id}'"
            })
            return

        body = self.read_json_body()
        if body is None:
            self.send_json(400, {
                "error": "Bad Request",
                "message": "Request body must be valid JSON"
            })
            return

        # Merge updates — do not allow overwriting the ID
        body.pop("transaction_id", None)
        TRANSACTIONS[idx].update(body)

        self.send_json(200, TRANSACTIONS[idx])

    # -----------------------------------------------------------------------
    # ROUTE: DELETE
    # -----------------------------------------------------------------------

    def do_DELETE(self):
        """
        DELETE /transactions/{id}
        → 200, confirmation | 404
        """
        if not self.check_auth():
            return

        tx_id = self.parse_id_from_path()
        if tx_id is None:
            self.send_json(400, {
                "error": "Bad Request",
                "message": "URL must include transaction ID: /transactions/{id}"
            })
            return

        idx, tx = self.find_transaction(tx_id)
        if tx is None:
            self.send_json(404, {
                "error": "Not Found",
                "message": f"No transaction with id '{tx_id}'"
            })
            return

        deleted = TRANSACTIONS.pop(idx)
        self.send_json(200, {
            "message": f"Transaction {tx_id} deleted successfully",
            "deleted": deleted
        })


# ---------------------------------------------------------------------------
# SERVER STARTUP
# ---------------------------------------------------------------------------

def run(port=PORT):
    server = HTTPServer(("", port), MoMoHandler)
    print(f"\n  MoMo SMS API running on http://localhost:{port}")
    print(f"  Transactions loaded: {len(TRANSACTIONS)}")
    print(f"  Credentials: {VALID_USER} / {VALID_PASS}")
    print(f"\n  Press Ctrl+C to stop\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Server stopped.")
        server.server_close()


if __name__ == "__main__":
    run()