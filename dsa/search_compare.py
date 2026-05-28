import sys
import os
import time
import random

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.parse_xml import TRANSACTIONS


def linear_search(transactions, target_id):
    for tx in transactions:
        if tx["transaction_id"] == target_id:
            return tx
    return None


def build_index(transactions):
    index = {}
    for tx in transactions:
        index[tx["transaction_id"]] = tx
    return index


def dict_lookup(index, target_id):
    return index.get(target_id)


def run_benchmark():
    transactions = TRANSACTIONS

    if len(transactions) < 20:
        print("not enough transactions loaded")
        return

    print(f"transactions loaded: {len(transactions)}")

    all_ids = [tx["transaction_id"] for tx in transactions]
    search_ids = random.sample(all_ids, 20)

    linear_times = []
    for tid in search_ids:
        start = time.perf_counter()
        linear_search(transactions, tid)
        end = time.perf_counter()
        linear_times.append((end - start) * 1_000_000) 

    index = build_index(transactions)

    dict_times = []
    for tid in search_ids:
        start = time.perf_counter()
        dict_lookup(index, tid)
        end = time.perf_counter()
        dict_times.append((end - start) * 1_000_000)

    avg_linear = sum(linear_times) / len(linear_times)
    avg_dict = sum(dict_times) / len(dict_times)

    print("\n--- results (20 searches) ---")
    print(f"linear search avg: {avg_linear:.4f} microseconds")
    print(f"dict lookup avg:   {avg_dict:.4f} microseconds")

    if avg_dict > 0:
        print(f"dict is ~{avg_linear / avg_dict:.1f}x faster")

    print("\nlinear search is O(n) - it checks every record until it finds a match")
    print("dict lookup is O(1) - python uses a hash table so it jumps straight to the value")
    print("for large datasets the difference gets bigger as n grows")
    print("\nother structures that could work:")
    print("- binary search tree: O(log n), good if you need range queries too")
    print("- sorted list + bisect: O(log n) without building a full dict")
    print("- hash set: if you only need to check if an id exists, not retrieve the record")


if __name__ == "__main__":
    run_benchmark()
