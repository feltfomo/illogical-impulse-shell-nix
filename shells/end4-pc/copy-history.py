import subprocess
import sys
import tempfile


def copy_history(decoder, entry_id):
    # Decode before acquiring the clipboard so a stale entry can't replace it with empty data.
    with tempfile.TemporaryFile() as payload:
        subprocess.run([decoder, "decode", entry_id], stdout=payload, check=True)
        payload.seek(0)
        encoding = subprocess.run(
            ["file", "--brief", "--mime-encoding", "-"],
            stdin=payload,
            stdout=subprocess.PIPE,
            check=True,
        ).stdout.strip()
        command = ["wl-copy"]
        # Content MIME guesses can classify ordinary To:/From: text as message/rfc822.
        # Keep automatic MIME detection for content file doesn't identify as UTF-8 text.
        if encoding in (b"us-ascii", b"utf-8"):
            command.extend(["--type", "text/plain;charset=utf-8"])
        payload.seek(0)
        subprocess.run(command, stdin=payload, check=True)


if __name__ == "__main__":
    try:
        copy_history(*sys.argv[1:])
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Clipboard history copy failed: {error}", file=sys.stderr)
        sys.exit(1)
