#!/bin/sh

test_description='pre-command hook'

. ./test-lib.sh

test_expect_success 'with no hook' '

	echo "first" > file &&
	git add file &&
	git commit -m "first"

'

# now install hook that always succeeds
HOOKDIR="$(git rev-parse --git-dir)/hooks"
HOOK="$HOOKDIR/pre-command"
mkdir -p "$HOOKDIR"
cat > "$HOOK" <<EOF
#!/bin/sh
exit 0
EOF
chmod +x "$HOOK"

test_expect_success 'with succeeding hook' '

	echo "second" >> file &&
	git add file &&
	git commit -m "second"

'

# now a hook that fails
cat > "$HOOK" <<EOF
#!/bin/sh
exit 1
EOF

test_expect_success 'with failing hook' '

	echo "third" >> file &&
	test_must_fail git add file &&
	test_must_fail git commit -m "third"

'

# now a hook that is non-executable
chmod -x "$HOOK"
test_expect_success POSIXPERM 'with non-executable hook' '

	echo "fourth" >> file &&
	git add file &&
	git commit -m "fourth"

'

test_done
