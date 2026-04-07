# Returns: 0 = all ok, 1 = missing hash file, 2 = hash mismatch
find "$MODPATH" -type f | grep -v '\.sha256$' | while read -r file; do
  name="${file##*/}"
  hashfile="${file}.sha256"

  ui_print "- Verifying $name..."

  [ -f "$hashfile" ] || { ui_print "! Missing hash: $name.sha256"; exit 1; }

  expected="$(cat "$hashfile" | tr -d '[:space:]')"
  actual="$(sha256sum "$file" | cut -d' ' -f1)"

  [ "$actual" = "$expected" ] || { ui_print "! Mismatch: $name"; exit 2; }
done