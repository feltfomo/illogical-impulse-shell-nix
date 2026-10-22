import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(sys.argv.pop(1))
HELPER = SOURCE / "scripts/clipboard/copy-history.py"


class ClipboardHistoryTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.db = str(self.directory / "history.db")
        self.config = str(self.directory / "unused-config")
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("CLIPHIST_") and key != "CLIPBOARD_STATE"
        }
        self.decoder = self.directory / "decode-history"
        self.decoder.write_text(
            f"#!{sys.executable}\nimport os, sys\n"
            f"os.execv({shutil.which('cliphist')!r}, "
            f"{[shutil.which('cliphist'), '--db-path', self.db, '--config-path', self.config]!r} + sys.argv[1:])\n"
        )
        self.decoder.chmod(0o755)
        self.capture = self.directory / "capture"
        self.args = self.directory / "args.json"
        copier = self.directory / "wl-copy"
        copier.write_text(
            f"#!{sys.executable}\nimport pathlib, json, sys\n"
            f"pathlib.Path({str(self.args)!r}).write_text(json.dumps(sys.argv[1:]))\n"
            f"pathlib.Path({str(self.capture)!r}).write_bytes(sys.stdin.buffer.read())\n"
        )
        copier.chmod(0o755)
        self.env["PATH"] = f"{self.directory}:{self.env['PATH']}"

    def store(self, payload):
        subprocess.run([str(self.decoder), "store"], input=payload, env=self.env, check=True)
        entry = subprocess.check_output([str(self.decoder), "list"], env=self.env)
        return entry.split(b"\t", 1)[0].decode()

    def copy(self, entry_id):
        return subprocess.run(
            [sys.executable, str(HELPER), str(self.decoder), entry_id],
            env=self.env,
            capture_output=True,
        )

    def assert_copy(self, payload, arguments):
        result = self.copy(self.store(payload))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.capture.read_bytes(), payload)
        self.assertEqual(json.loads(self.args.read_text()), arguments)

    def test_header_like_text(self):
        self.assert_copy(
            b"To: architecture\nFrom: implementation\n\n100% complete; \\n stays literal. 'single' \"double\" $(false) `false`\n\n",
            ["--type", "text/plain;charset=utf-8"],
        )

    def test_utf8_text(self):
        self.assert_copy("Pasted caf\u00e9\n".encode(), ["--type", "text/plain;charset=utf-8"])

    def test_literal_image_marker_text(self):
        self.assert_copy(b"[[ binary data 123 B png 20x20 ]]", ["--type", "text/plain;charset=utf-8"])

    def test_image(self):
        self.assert_copy(
            base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="),
            [],
        )

    def test_binary(self):
        self.assert_copy(bytes(range(256)), [])

    def test_decode_failure(self):
        self.store(b"existing history")
        self.capture.write_bytes(b"existing clipboard")
        result = self.copy("999999")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.capture.read_bytes(), b"existing clipboard")
        self.assertFalse(self.args.exists())

    def test_copy_failure(self):
        (self.directory / "wl-copy").write_text(f"#!{sys.executable}\nimport sys\nsys.exit(7)\n")
        self.assertNotEqual(self.copy(self.store(b"text")).returncode, 0)

    def test_partial_decode_failure(self):
        self.decoder.write_text(
            f"#!{sys.executable}\nimport sys\nsys.stdout.write('partial')\nsys.exit(1)\n"
        )
        self.assertNotEqual(self.copy("1").returncode, 0)
        self.assertFalse(self.args.exists())

    def test_encoding_failure(self):
        detector = self.directory / "file"
        detector.write_text(f"#!{sys.executable}\nimport sys\nsys.exit(1)\n")
        detector.chmod(0o755)
        self.assertNotEqual(self.copy(self.store(b"text")).returncode, 0)
        self.assertFalse(self.args.exists())

    def test_qml_uses_shared_helper(self):
        service = (SOURCE / "services/Cliphist.qml").read_text()
        self.assertIn('/clipboard/copy-history.py`, root.cliphistBinary, root.entryId(entry)', service)
        self.assertIn('Quickshell.execDetached(root.copyArguments(entry))', service)
        self.assertEqual(service.count('${root.copyCommand(entry)} &&'), 2)
        self.assertNotIn('| wl-copy', service)


if __name__ == "__main__":
    unittest.main()
