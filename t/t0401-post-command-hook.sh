#!/bin/sh

test_description='post-command hook'

. ./test-lib.sh

test_expect_success 'with no hook' '

	echo "first" > file &&
	git add file &&
	git commit -m "first"

'

# now install hook that outputs a file
HOOKDIR="$(git rev-parse --git-dir)/hooks"
HOOK="$HOOKDIR/post-command"
mkdir -p "$HOOKDIR"
cat > "$HOOK" <<EOF
#!/bin/sh
echo test >> post-command.txt
exit 0
EOF
chmod +x "$HOOK"

test_expect_success 'post command hook runs' '

	echo "second" >> file &&
	git add file &&
	test_path_is_file post-command.txt

'

# now a hook that is non-executable
chmod -x "$HOOK"
test_expect_success POSIXPERM 'non-executable hook doesnt run' '

    rm post-command.txt &&
	echo "third" >> file &&
	git add file &&
	test_path_is_missing post-command.txt

'

test_done
