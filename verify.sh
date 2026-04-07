find "$MODPATH" -type f | grep -v '\.sha256$' | while read -r file; do
  name="${file##*/}"
  hashfile="${file}.sha256"

  ui_print "- Verifying $name..."

  [ -f "$hashfile" ] || abort "! Missing hash file: ${hashfile##"$MODPATH/"}"

  expected="$(cat "$hashfile" | tr -d '[:space:]')"
  actual="$(sha256sum "$file" | cut -d' ' -f1)"

  [ "$actual" = "$expected" ] || abort "! Integrity check failed: $name"
done

ui_print "- All files verified."