"""
app.py — Entry point for the MoMo SMS REST API.
Imports and starts the server defined in api.py.

Run with:  python api/app.py

"""
from api.api import run

if __name__ == "__main__":
    run()