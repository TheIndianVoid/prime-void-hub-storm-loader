#!/usr/bin/env python3
"""Obscura native profile, without the executor-incompatible anti-tamper guards.

The original --mode native maps to MAXIMUM, which defaults anti_tamper=True
and inserts checks that abort if getgenv/hookfunction/etc exist. Prime Void Hub
requires such executor APIs. Preserve the other seven native Obscura layers.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("--obscura-root", type=pathlib.Path, default=pathlib.Path("/tmp/obscura"))
    parser.add_argument("-o", "--output", type=pathlib.Path, required=True)
    args = parser.parse_args()

    sys.path.insert(0, str(args.obscura_root.resolve()))
    from config import ObfuscationConfig, ProtectionLevel
    from obfuscator import Obfuscator

    cfg = ObfuscationConfig(level=ProtectionLevel.MAXIMUM)
    cfg.anti_tamper = False
    if cfg.virtualize or not cfg.table_indirection or not cfg.encrypt_strings:
        raise RuntimeError("Unexpected native Obscura settings")
    source = args.source.read_text(encoding="utf-8")
    result = Obfuscator(cfg).obfuscate(source)
    if "-- Obscura [" not in result:
        raise RuntimeError("Obscura output signature missing")

    # This fatal guard was present in every protected port produced by
    # --mode native. Reject accidental reintroduction in future builds.
    rejection = r"if\s+[A-Za-z_]\w*\(getgenv\)\s*~=\s*[A-Za-z_]\w*\(nil\)\s+then\s+error"
    if re.search(rejection, result):
        raise RuntimeError("Incompatible executor-detection guard remains in artifact")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(result, encoding="utf-8")
    print(
        f"Obscura native-compatible: {args.source.name}: "
        f"{len(source.encode('utf-8'))} -> {len(result.encode('utf-8'))} bytes"
    )


if __name__ == "__main__":
    main()
