#!/bin/sh

test_description='sparse checkout hashmap tests'

. ./test-lib.sh

test_expect_success 'setup' '
	echo "initial" >a &&
	echo "initial" >b &&
	echo "initial" >c &&
	git add a b c &&
	git commit -m "initial commit"
'

test_expect_success 'create feature branch' '
	git checkout -b feature &&
	echo "modified" >b &&
	echo "modified" >c &&
	git add b c &&
	git commit -m "modification"
'

test_expect_success 'perform sparse checkout of master' '
	git config --local --bool core.sparsecheckout true &&
	git config --local core.gvfs 2 &&
	echo "/a" >.git/info/sparse-checkout &&
	echo "/c" >>.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c
'

test_expect_success 'merge feature branch into sparse checkout of master' '
	git merge feature &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c &&
	test "$(cat c)" = "modified"
'

test_expect_success 'return to full checkout of master' '
	git checkout feature &&
	echo "/b" >>.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file a &&
	test_path_is_file b &&
	test_path_is_file c &&
	test "$(cat b)" = "modified"
'

test_expect_success 'perform sparse checkout of master with a directory' '
	mkdir one &&
	mkdir one/two &&
	echo "initial" >one/a &&
	echo "initial" >one/b &&
	echo "initial" >one/two/a &&
	echo "initial" >one/two/b &&
	git add one/a one/b one/two/a one/two/b &&
	git commit -m "directory commit" &&
	echo "/one/" >.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file one/a &&
	test_path_is_file one/b &&
	test_path_is_missing one/two/a &&
	test_path_is_missing one/two/a &&
	test_path_is_missing a &&
	test_path_is_missing b &&
	test_path_is_missing c
'

test_expect_success 'perform sparse checkout of master with a shell glob' '
	echo "a" >>.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file one/a &&
	test_path_is_file one/b &&
	test_path_is_file one/two/a &&
	test_path_is_missing one/two/b &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_missing c
'

test_expect_success 'perform sparse checkout of master with a directory and files' '
	echo "/a" >>.git/info/sparse-checkout &&
	echo "/b" >>.git/info/sparse-checkout &&
	echo "/c" >>.git/info/sparse-checkout &&
	echo "/one/two/" >>.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file one/a &&
	test_path_is_file one/b &&
	test_path_is_file one/two/a &&
	test_path_is_file one/two/b &&
	test_path_is_file a &&
	test_path_is_file b &&
	test_path_is_file c
'

test_done
