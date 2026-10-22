# Clipboard history copying

`clipboard.patch` routes the Cliphist service's copy, paste and superpaste actions
through `scripts/clipboard/copy-history.py`. The source package installs that helper;
the runtime package supplies Python, cliphist, file and wl-copy on its launcher PATH.
The patch targets end4-pC revision `abde3ab4d8e388280b0837879fd25e1f4a794297`,
locked in `flake.lock`.

Cliphist stores payload bytes without their original MIME types. The helper decodes
an entry by ID into a temporary file, then asks file for its encoding. ASCII and
UTF-8 text use `text/plain;charset=utf-8`, so text beginning with mail headers
doesn't become `message/rfc822`. Other encodings keep wl-copy's automatic MIME
detection, preserving the previous behavior for images and binary content. This
doesn't recover the original MIME type or promise to identify every binary format.
The helper sends the decoded bytes unchanged, including trailing newlines.

Decode or encoding-detection failures stop before wl-copy runs. A failed clipboard
copy returns a failure status, preventing a chained paste. Screenshot copying,
URI-list copying and Quickshell's text clipboard assignments have separate owners.

Building `end4-pc-source` runs `test-clipboard.py` against the patched output. Tests
use an isolated real cliphist database and a fake wl-copy; they never acquire the
session clipboard. They cover header-like text, UTF-8, literal image-marker text,
image and binary bytes, decoder failure and clipboard-command failure.

After installing the rebuilt runtime through the host's existing configuration,
restart the shell through its normal launcher. The launcher updates the managed
configuration symlink to the patched source. Building alone doesn't activate it.
