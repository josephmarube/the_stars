import xml.etree.ElementTree as ET
import re
from pathlib import Path
from collections import Counter

XML_PATH = Path(__file__).resolve().parent.parent / "data" / "raw" / "modified_sms_v2.xml"


def categorize(body: str) -> str:
    if "<#>" in body or "one-time password" in body:
        return "Unknown"
    if "via agent:" in body and "withdrawn" in body:
        return "Agent Withdrawal"
    if body.startswith("You have received"):
        return "Incoming Money"
    if body.startswith("*165*S*"):
        return "Transfer to Mobile"
    if body.startswith("*113*R*"):
        return "Bank Deposit"
    if body.startswith("*162*") and "Airtime" in body:
        return "Airtime Purchase"
    if body.startswith("*162*") and "Cash Power" in body:
        return "Airtime Purchase"
    if body.startswith("*164*"):
        return "Unknown"
    if body.startswith("TxId:") and "Your payment of" in body:
        return "Payment to Code"
    return "Unknown"


AMOUNT_RE = re.compile(r"([\d,]+)\s*RWF")

def extract_amount(body: str) -> float | None:
    m = AMOUNT_RE.search(body)
    if not m:
        return None
    return float(m.group(1).replace(",", ""))


TXID_RE  = re.compile(r"TxId:\s*(\d+)")
FINID_RE = re.compile(r"Financial Transaction Id:\s*(\d+)")

def extract_ref_code(body: str) -> str | None:
    m = TXID_RE.search(body) or FINID_RE.search(body)
    return m.group(1) if m else None


INCOMING_SENDER_RE   = re.compile(r"received [\d,]+ RWF from (.+?)\s*\(")
PAYMENT_RECEIVER_RE  = re.compile(r"payment of [\d,]+ RWF to (.+?)\s+\d{4,}")
TRANSFER_RECEIVER_RE = re.compile(r"transferred to (.+?)\s*\(\d+\)")
AGENT_NAME_RE        = re.compile(r"via agent:\s*(.+?)\s*\(\d+\)")

def extract_sender_receiver(body: str, category: str) -> tuple[str | None, str | None]:
    if category == "Incoming Money":
        m = INCOMING_SENDER_RE.search(body)
        return (m.group(1).strip() if m else None, "self")
    if category == "Payment to Code":
        m = PAYMENT_RECEIVER_RE.search(body)
        return ("self", m.group(1).strip() if m else None)
    if category == "Transfer to Mobile":
        m = TRANSFER_RECEIVER_RE.search(body)
        return ("self", m.group(1).strip() if m else None)
    if category == "Bank Deposit":
        return ("bank/agent", "self")
    if category == "Airtime Purchase":
        return ("self", "MTN Airtime")
    if category == "Agent Withdrawal":
        m = AGENT_NAME_RE.search(body)
        return ("self", m.group(1).strip() if m else None)
    return (None, None)


def parse_one(sms_elem) -> dict | None:
    body      = sms_elem.get("body") or ""
    timestamp = sms_elem.get("readable_date") or sms_elem.get("date")
    category  = categorize(body)
    if category == "Unknown":
        return None
    sender, receiver = extract_sender_receiver(body, category)
    return {
        "transaction_id": None,
        "type":           category,
        "amount":         extract_amount(body),
        "sender":         sender,
        "receiver":       receiver,
        "timestamp":      timestamp,
        "ref_code":       extract_ref_code(body),
    }


def load_transactions() -> list[dict]:
    if not XML_PATH.exists():
        print(f"[parse_xml] ERROR: XML not found at {XML_PATH}")
        return []
    tree    = ET.parse(XML_PATH)
    root    = tree.getroot()
    out     = []
    skipped = 0
    next_id = 1
    for sms in root.findall("sms"):
        rec = parse_one(sms)
        if rec is None:
            skipped += 1
            continue
        rec["transaction_id"] = next_id
        next_id += 1
        out.append(rec)
    print(f"[parse_xml] loaded {len(out)} transactions, skipped {skipped}")
    return out


TRANSACTIONS = load_transactions()


if __name__ == "__main__":
    print(f"\nTotal loaded: {len(TRANSACTIONS)}")
    print("\nFirst 3 records:")
    for tx in TRANSACTIONS[:3]:
        for k, v in tx.items():
            print(f"  {k:<16} {v}")
        print()
    print("Category breakdown:")
    counts = Counter(tx["type"] for tx in TRANSACTIONS)
    for cat, n in counts.most_common():
        print(f"  {cat:<26} {n}")