find . -maxdepth 3 -type f \
  \( -name 'lakefile*' -o -name 'lean-toolchain' -o -name '*.lean' \) \
  -print | sort

echo "----- lakefile.lean -----"
cat lakefile.lean 2>/dev/null || true

echo "----- lakefile.toml -----"
cat lakefile.toml 2>/dev/null || true

echo "----- formal tree -----"
find formal -maxdepth 3 -print 2>/dev/null | sort
