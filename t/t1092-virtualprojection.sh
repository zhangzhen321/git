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

test_expect_success 'test hook parameters and version' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	if test "$#" -ne 1
	then
		echo "$0: Exactly 1 argument expected" >&2
		exit 2
	fi

	if test "$1" != 1
	then
		echo "$0: Unsupported hook version." >&2
		exit 1
	fi
	EOF
	git status &&
	write_script .git/hooks/virtualProjection <<-\EOF &&
		exit 3;
	EOF
	test_must_fail git status
'

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
EOF

test_expect_success 'verify folder wild cards' '
	mkdir all &&
	touch all/a &&
	touch all/b &&
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
S all/b
S b
EOF

test_expect_success 'verify shell globs' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "a\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'

cat > expected <<EOF
H a
H all/a
H all/b
S b
EOF

test_expect_success 'verify shell globs with folder wild cards' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/all/\0"
	printf "a\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'


cat > expected <<EOF
H a
H all/a
H all/b
H b
EOF

test_expect_success 'verify shell globs, folder wild cards and absolute paths' '
	write_script .git/hooks/virtualProjection <<-\EOF &&
	printf "/all/\0"
	printf "a\0"
	printf "/b\0"
	EOF
	git ls-files -v > actual &&
	test_cmp expected actual
'
test_done
