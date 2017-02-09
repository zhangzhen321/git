#!/bin/sh

test_description='pre-command hook'

. ./test-lib.sh

test_expect_success 'with no hook' '
	echo "first" > file &&
	git add file &&
	git commit -m "first"
'

#test_expect_success 'with succeeding hook' '
#	write_script pre-command <<-EOF &&
#	echo "\$*" >\$(git rev-parse --git-dir)/pre-command.out
#	EOF
#	PATH="$PATH:." &&
#	echo "second" >> file &&
#	git add file &&
#	test "add file" = "$(cat .git/pre-command.out)"
#'

#test_expect_success 'with failing hook' '
#	write_script pre-command <<-EOF &&
#	exit 1
#	EOF
#	PATH="$PATH:." &&
#	echo "third" >> file &&
#	test_must_fail git add file &&
#	test_path_is_missing "$(cat .git/pre-command.out)"
#'

test_done
