#!/usr/bin/env python3
"""Group YouTube JSON3 captions into timestamped text without editing their wording."""

import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import sys


def positive_int(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return number


def normalize(document, interval):
    if not isinstance(document, dict) or not isinstance(document.get("events"), list):
        raise ValueError("expected a JSON3 object with an events array")

    groups = defaultdict(list)
    for event in document["events"]:
        if not isinstance(event, dict):
            raise ValueError("caption event must be an object")
        segments = event.get("segs", [])
        if not isinstance(segments, list):
            raise ValueError("caption segments must be an array")
        words = []
        for segment in segments:
            if not isinstance(segment, dict) or not isinstance(segment.get("utf8", ""), str):
                raise ValueError("caption segment must contain text")
            words.append(segment.get("utf8", ""))
        text = " ".join("".join(words).split())
        if not text:
            continue

        start = event.get("tStartMs")
        if (
            isinstance(start, bool)
            or not isinstance(start, (int, float))
            or not math.isfinite(start)
            or start < 0
        ):
            raise ValueError("text-bearing caption event has an invalid tStartMs")
        bucket = int(start // (interval * 1000)) * interval
        groups[bucket].append(text)

    if not groups:
        raise ValueError("no caption text found")

    paragraphs = []
    for seconds, texts in sorted(groups.items()):
        hours, remainder = divmod(seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        paragraphs.append(f"[{hours:02}:{minutes:02}:{seconds:02}] {' '.join(texts)}")
    return "\n\n".join(paragraphs) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captions", type=Path, help="downloaded .json3 caption file")
    parser.add_argument("--output", required=True, type=Path, help="new UTF-8 transcript file")
    parser.add_argument("--interval", type=positive_int, default=30, help="bucket size in seconds")
    args = parser.parse_args()

    try:
        with args.captions.open(encoding="utf-8-sig") as source:
            text = normalize(json.load(source), args.interval)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x", encoding="utf-8", newline="\n") as destination:
            destination.write(text)
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Saved transcript: {args.output.resolve()}")
    print(f"Words (including timestamps): {len(text.split())}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
