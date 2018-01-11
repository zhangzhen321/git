#!/bin/sh

test_description='virtual checkout hashmap tests'

. ./test-lib.sh

test_expect_success 'setup' '
	mkdir .git/hooks/ &&
	echo "initial" >a &&
	echo "initial" >b &&
	git add a b &&
	git commit -m "initial commit" &&
	git config --local core.virtualProjection .git/hooks/virtualProjection
'

cat > .gitignore <<\EOF
.gitignore
expect*
actual*
EOF

cat > expected <<EOF
H a
S b
EOF

test_expect_success 'verify skip-worktree bit is set for absolute path' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/a\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'

cat > expected <<EOF
S a
H b
EOF

test_expect_success 'verify skip-worktree bit is cleared for absolute path' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/b\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'

cat > expected <<EOF
H a
H all/a
H all/b
S b
S none/a
S none/b
EOF

test_expect_success 'verify folder wild cards' '
	mkdir all &&
	touch all/a &&
	touch all/b &&
	mkdir none&&
	touch none/a &&
	touch none/b &&
	git add . &&
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/all/\0"
	printf "/a\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'

cat > expected <<EOF
H a
H all/a
H all/b
S b
H none/a
S none/b
EOF

test_expect_success 'verify shell globs' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/all/\0"
	printf "a\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'

test_done

test_expect_success 'verify skip-worktree bit is set by virtual projection' '
	git config --local core.virtualProjection .git/hooks/virtualProjection &&
	mkdir .git/hooks/ &&
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/a\0"
	printf "/c\0"
	EOF
	git checkout &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c
'

test_expect_success 'create feature branch' '
	git checkout -b feature &&
	echo "modified" >b &&
	echo "modified" >c &&
	git add b c &&
	git commit -m "modification"
'

test_expect_success 'perform virtual checkout of master' '
	git config --local core.virtualProjection .git/hooks/virtualProjection &&
	mkdir .git/hooks/ &&
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/a\0"
	printf "/c\0"
	EOF
	git checkout master &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c
'

test_expect_success 'merge feature branch into virtual checkout of master' '
	git merge feature &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c &&
	test "$(cat c)" = "modified"
'

test_expect_success 'return to full checkout of master' '
	git checkout feature &&
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/\0"
	EOF
	git checkout master &&
	test_path_is_file a &&
	test_path_is_file b &&
	test_path_is_file c &&
	test "$(cat b)" = "modified"
'

test_expect_success 'perform virtual checkout of master with a directory' '
	mkdir one &&
	mkdir one/two &&
	mkdir one/two/three &&
	echo "initial" >one/a &&
	echo "initial" >one/b &&
	echo "initial" >one/two/a &&
	echo "initial" >one/two/b &&
	echo "initial" >one/two/three/a &&
	echo "initial" >one/two/three/b &&
	git add --all &&
	git commit -m "directory commit" &&
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "one/two/\0"
	EOF
	git checkout master &&
	test_path_is_missing a &&
	test_path_is_missing b &&
	test_path_is_missing c &&
	test_path_is_missing one/a &&
	test_path_is_missing one/b &&
	test_path_is_file one/two/a &&
	test_path_is_file one/two/b &&
	test_path_is_file one/two/three/a &&
	test_path_is_file one/two/three/b
'

test_expect_success 'perform virtual checkout of master with a shell glob' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "a\0"
	EOF
	git checkout master &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_missing c &&
	test_path_is_file one/a &&
	test_path_is_missing one/b &&
	test_path_is_file one/two/a &&
	test_path_is_file one/two/b &&
	test_path_is_file one/two/three/a &&
	test_path_is_file one/two/three/b
'

test_expect_success 'perform virtual checkout of master with a directory and files' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "a\0"
	printf "b\0"
	printf "c\0"
	printf "one/two/\0"
	EOF
	git checkout master &&
	test_path_is_file a &&
	test_path_is_file b &&
	test_path_is_file c &&
	test_path_is_file one/a &&
	test_path_is_missing one/b &&
	test_path_is_file one/two/a &&
	test_path_is_file one/two/b &&
	test_path_is_file one/two/three/a &&
	test_path_is_file one/two/three/b
'

test_done
