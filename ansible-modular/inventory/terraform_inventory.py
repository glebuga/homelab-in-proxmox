#!/usr/bin/env python3

from __future__ import annotations

import datetime
import json
import os
import subprocess
import sys

import yaml

# terraform-modular lives alongside ansible-modular (one level up).
TERRAFORM_DIR = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "terraform-modular")
)
# mapping.yml lives next to this script.
MAPPING_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mapping.yml")

DEFAULT_ADMIN_USER = "admin"
DEFAULT_BOOTSTRAP_USER = "root"


def _terraform_output():
    """Return terraform outputs as {name: value}, or {} if unavailable."""
    try:
        result = subprocess.run(
            ["terraform", "-chdir=" + TERRAFORM_DIR, "output", "-json"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        sys.stderr.write(
            "WARNING: could not read terraform output from %s: %s\n"
            "         run 'terraform apply' in terraform-modular/ first.\n" % (TERRAFORM_DIR, exc)
        )
        return {}
    try:
        raw = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        sys.stderr.write("WARNING: failed to parse terraform output: %s\n" % exc)
        return {}
    return {key: data.get("value") for key, data in raw.items()}


def _first_ip(value):
    """Extract a single IPv4 string from a terraform output value.

    Handles plain strings, lists (e.g. proxmox ``ipv4_addresses``) and dicts.
    """
    if isinstance(value, str):
        return value or None
    if isinstance(value, list):
        for item in value:
            ip = _first_ip(item)
            if ip:
                return ip
        return None
    if isinstance(value, dict):
        for v in value.values():
            ip = _first_ip(v)
            if ip:
                return ip
    return None


def _load_mapping():
    """Load the declarative host mapping from mapping.yml."""
    try:
        with open(MAPPING_FILE) as fh:
            return yaml.safe_load(fh) or {}
    except OSError as exc:
        sys.stderr.write("WARNING: could not read mapping file %s: %s\n" % (MAPPING_FILE, exc))
        return {}


def build_inventory():
    out = _terraform_output()
    mapping = _load_mapping()

    # Collect every group mentioned in the mapping so empty groups still exist.
    groups: dict[str, list[str]] = {}
    for spec in mapping.values():
        for g in spec.get("groups", []):
            groups.setdefault(g, [])

    hostvars: dict[str, dict] = {}

    def _register(host, ip, spec):
        if not host or not ip:
            return
        for g in spec.get("groups", []):
            groups.setdefault(g, [])
            if host not in groups[g]:
                groups[g].append(host)
        hv = {"ansible_host": ip}
        if spec.get("bootstrap"):
            hv["bootstrap_user"] = DEFAULT_BOOTSTRAP_USER
        hv["ansible_user"] = spec.get("user", DEFAULT_ADMIN_USER)
        hostvars[host] = hv

    for out_key, spec in mapping.items():
        value = out.get(out_key)
        if value is None:
            continue
        if spec.get("host"):
            # Simple host: output is a single IP / string.
            _register(spec["host"], _first_ip(value), spec)
        elif spec.get("host_prefix"):
            # VM dict: output is keyed by vm_id -> build name dynamically.
            prefix = spec["host_prefix"]
            for vm_id, ip in (value or {}).items():
                _register("%s%s" % (prefix, vm_id), _first_ip(ip), spec)
        else:
            sys.stderr.write(
                "WARNING: mapping entry '%s' needs 'host' or 'host_prefix'\n" % out_key
            )

    # Local control host (hq) is always present, never from terraform.
    groups["local"] = ["hq"]
    hostvars["hq"] = {
        "ansible_connection": "local",
        "ansible_host": "127.0.0.1",
    }

    # No global vars here — they come from inventory/group_vars/all/main.yml.
    return {
        "all": {"vars": {}},
        **groups,
        "_meta": {"hostvars": hostvars},
    }


def write_report(inv, path):
    """Write a human-readable hosts report next to the inventory script."""
    groups = {g: hosts for g, hosts in inv.items() if isinstance(hosts, list)}
    hostvars = inv.get("_meta", {}).get("hostvars", {})

    # host -> list of groups
    host_groups = {}
    for g, hosts in groups.items():
        for h in hosts:
            host_groups.setdefault(h, []).append(g)

    def dns_for(host, grps):
        if host == "hq":
            return "local"
        if "net_service" in grps:
            return "192.168.0.1 (upstream router, authoritative)"
        if "kuber" in grps:
            return "192.168.0.1 (router, by design)"
        return "10.0.0.104 (internal dnsmasq)"

    lines = []
    lines.append("=" * 64)
    lines.append(" Homelab Inventory Report")
    lines.append(" Generated: %s" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    lines.append(" Source: terraform -chdir=../terraform-modular output -json")
    lines.append("=" * 64)
    lines.append("")
    lines.append("HOSTS")
    lines.append("-" * 64)
    lines.append("%-15s %-15s %-20s %-7s %-9s %s" % ("Name", "IP", "Groups", "User", "Bootstrap", "Conn"))
    lines.append("-" * 64)
    for host in sorted(host_groups):
        hv = hostvars.get(host, {})
        ip = hv.get("ansible_host", "-")
        grps = host_groups[host]
        user = hv.get("ansible_user", "-")
        boot = hv.get("bootstrap_user", "-")
        conn = hv.get("ansible_connection", "ssh")
        lines.append("%-15s %-15s %-20s %-7s %-9s %s" % (
            host, ip, ",".join(grps), user, boot, conn))
    lines.append("")
    lines.append("DNS")
    lines.append("-" * 64)
    for host in sorted(host_groups):
        lines.append("%-15s -> %s" % (host, dns_for(host, host_groups[host])))
    lines.append("")
    lines.append("GROUPS")
    lines.append("-" * 64)
    for g, hosts in groups.items():
        if hosts:
            lines.append("%-14s : %s" % (g, ", ".join(hosts)))
    lines.append("")

    try:
        with open(path, "w") as fh:
            fh.write("\n".join(lines) + "\n")
    except OSError as exc:
        sys.stderr.write("WARNING: could not write report to %s: %s\n" % (path, exc))


def main(argv):
    if len(argv) > 1 and argv[1] == "--host":
        print(json.dumps({}))
        return 0
    if len(argv) > 1 and argv[1] == "--list":
        inv = build_inventory()
        print(json.dumps(inv))
        report_path = os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "hosts_report.txt"
        )
        write_report(inv, report_path)
        return 0
    sys.stderr.write("usage: terraform_inventory.py [--list | --host <host>]\n")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
