#!/usr/bin/env python3
"""
Automated offline bake script for OPNsense QCOW2 images.
Injects config/config.xml into a base OPNsense image via a headless QEMU micro-boot.
Supports both standalone full copies and lightweight Copy-on-Write overlays.
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
import pexpect


def log(msg: str) -> None:
    now = time.strftime("%H:%M:%S")
    print(f"[{now}] {msg}", flush=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Bake OPNsense config.xml into a QCOW2 disk image offline."
    )
    parser.add_argument(
        "--source",
        default="images/OPNsense-26.7.qcow2",
        help="Path to source OPNsense QCOW2 base image (default: images/OPNsense-26.7.qcow2)",
    )
    parser.add_argument(
        "--config",
        default="config/config.xml",
        help="Path to OPNsense configuration XML file (default: config/config.xml)",
    )
    parser.add_argument(
        "--output",
        default="images/OPNsense-26.7-configured.qcow2",
        help="Path to output baked QCOW2 image (default: images/OPNsense-26.7-configured.qcow2)",
    )
    parser.add_argument(
        "--mode",
        choices=["standalone", "overlay"],
        default="standalone",
        help="Bake mode: 'standalone' (full independent copy ~2.1GB) or 'overlay' (CoW diff layer ~20MB)",
    )
    parser.add_argument(
        "--memory",
        type=int,
        default=2048,
        help="RAM in MiB for QEMU micro-boot (default: 2048)",
    )
    parser.add_argument(
        "--smp",
        type=int,
        default=2,
        help="vCPUs for QEMU micro-boot (default: 2)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="Timeout in seconds for QEMU operations (default: 120)",
    )
    return parser.parse_args()


def build_config_iso(config_path: str, iso_path: str) -> None:
    with tempfile.TemporaryDirectory() as staging:
        conf_dir = os.path.join(staging, "conf")
        os.makedirs(conf_dir, exist_ok=True)
        shutil.copy2(config_path, os.path.join(conf_dir, "config.xml"))

        cmd = [
            "genisoimage",
            "-r",
            "-J",
            "-V",
            "CONFIG",
            "-o",
            iso_path,
            staging,
        ]
        log(f"Building ephemeral config ISO from {config_path}...")
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            sys.exit(f"Failed to generate config ISO: {res.stderr}")


def prepare_target_image(source: str, output: str, mode: str) -> None:
    abs_source = os.path.abspath(source)
    abs_output = os.path.abspath(output)

    if os.path.exists(abs_output):
        log(f"Removing existing target image at {abs_output}...")
        os.remove(abs_output)

    os.makedirs(os.path.dirname(abs_output), exist_ok=True)

    if mode == "standalone":
        log(f"Creating standalone copy: {abs_source} -> {abs_output}...")
        start = time.time()
        cmd = ["qemu-img", "convert", "-O", "qcow2", abs_source, abs_output]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            sys.exit(f"qemu-img convert failed: {res.stderr}")
        log(f"Standalone copy created in {time.time() - start:.1f}s")
    else:
        log(f"Creating CoW overlay referencing base {abs_source}...")
        cmd = ["qemu-img", "create", "-f", "qcow2", "-b", abs_source, "-F", "qcow2", abs_output]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            sys.exit(f"qemu-img create overlay failed: {res.stderr}")
        log("CoW overlay initialized.")


def bake_config(target_image: str, iso_path: str, memory: int, smp: int, timeout: int) -> None:
    qemu_cmd = (
        f"qemu-system-x86_64 -enable-kvm -m {memory} -smp {smp} -nographic "
        f"-drive file={target_image},if=virtio -drive file={iso_path},media=cdrom"
    )

    log("Booting headless QEMU micro-instance with KVM acceleration...")
    start_time = time.time()
    child = pexpect.spawn(qemu_cmd, timeout=timeout, encoding="utf-8")

    try:
        # Wait for the FreeBSD / OPNsense console login prompt
        log("Waiting for OPNsense boot and console login prompt...")
        child.expect("login:")
        log(f"Console login prompt reached in {time.time() - start_time:.1f}s")

        # Authenticate with default credentials
        log("Sending credentials (root / opnsense)...")
        child.sendline("root")
        child.expect("Password:")
        child.sendline("opnsense")

        # Wait specifically for the OPNsense menu prompt
        child.expect("Enter an option:")
        log("Console menu reached. Selecting Option 8 (Shell)...")
        child.sendline("8")

        # Wait for root shell prompt
        child.expect("root@OPNsense:~ #")
        log("In root shell! Mounting ephemeral ISO and copying config.xml...")

        child.sendline("mkdir -p /mnt/iso && mount_cd9660 /dev/cd0 /mnt/iso")
        child.expect("root@OPNsense:~ #")

        child.sendline("cp /mnt/iso/conf/config.xml /conf/config.xml && rm -rf /tmp/config.cache")
        child.expect("root@OPNsense:~ #")

        child.sendline("umount /mnt/iso")
        child.expect("root@OPNsense:~ #")

        # Verify config exists
        child.sendline("grep '<hostname>' /conf/config.xml")
        child.expect("root@OPNsense:~ #")
        log(f"Verified config.xml: {child.before.strip()}")

        log("Exiting shell back to console menu...")
        child.sendline("exit")
        child.expect("Enter an option:")

        log("Selecting Option 5 (Power off system)...")
        child.sendline("5")
        child.expect(r"\[y/N\]:")

        log("Confirming shutdown...")
        child.sendline("y")
        child.expect(pexpect.EOF)
        log(f"QEMU guest shutdown complete. Total time: {time.time() - start_time:.1f}s")

    except pexpect.TIMEOUT:
        log("ERROR: Timed out waiting for console response.")
        if child.before:
            print("Last console output:\n", child.before[-1000:])
        child.close(force=True)
        sys.exit(1)
    except pexpect.EOF:
        log("ERROR: Unexpected EOF from QEMU process.")
        if child.before:
            print("Last console output:\n", child.before[-1000:])
        sys.exit(1)
    finally:
        if child.isalive():
            child.close(force=True)


def main() -> None:
    args = parse_args()

    if not os.path.isfile(args.source):
        sys.exit(f"Error: Source image not found at '{args.source}'")
    if not os.path.isfile(args.config):
        sys.exit(f"Error: Configuration XML not found at '{args.config}'")

    abs_source = os.path.abspath(args.source)
    abs_config = os.path.abspath(args.config)
    abs_output = os.path.abspath(args.output)

    log(f"Source image: {abs_source}")
    log(f"Config XML:   {abs_config}")
    log(f"Target image: {abs_output}")
    log(f"Mode:         {args.mode.upper()}")

    with tempfile.TemporaryDirectory() as tmpdir:
        iso_path = os.path.join(tmpdir, "ephemeral_config.iso")
        build_config_iso(abs_config, iso_path)
        prepare_target_image(abs_source, abs_output, args.mode)
        bake_config(abs_output, iso_path, args.memory, args.smp, args.timeout)

    file_size_mb = os.path.getsize(abs_output) / (1024 * 1024)
    log(f"SUCCESS: Baked image ready at {abs_output} ({file_size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
