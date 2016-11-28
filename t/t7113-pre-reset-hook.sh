#!/bin/sh

test_description='pre-command hook'

. ./test-lib.sh

test_expect_success 'with no hook' '

	echo "first" > file &&
	git add file &&
	git commit -m "first" &&
	git reset

'

# now install hook that always succeeds
HOOKDIR="$(git rev-parse --git-dir)/hooks"
HOOK="$HOOKDIR/pre-reset"
mkdir -p "$HOOKDIR"
cat > "$HOOK" <<EOF
#!/bin/sh
exit 0
EOF
chmod +x "$HOOK"

test_expect_success 'with succeeding hook' '

	echo "second" >> file &&
	git add file &&
	git reset

'

test_expect_success 'file with succeeding hook' '

	echo "third" >> file &&
	git add file &&
	git reset HEAD file

'

test_expect_success '--hard with succeeding hook' '

	echo "fourth" >> file &&
	git add file &&
	git reset --hard

'

# now a hook that fails
cat > "$HOOK" <<EOF
#!/bin/sh
exit 1
EOF

test_expect_success 'with failing hook' '

	echo "fifth" >> file &&
	git add file &&
	test_must_fail git reset HEAD file

'

# now a hook that is non-executable
chmod -x "$HOOK"
test_expect_success POSIXPERM 'with non-executable hook' '

	echo "sixth" >> file &&
	git add file &&
	git reset HEAD file

'

test_done
