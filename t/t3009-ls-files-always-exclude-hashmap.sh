#!/bin/sh

test_description='always_exclude hashmap tests'

. ./test-lib.sh

test_expect_success 'setup' '
	mkdir -p dir1/dir2 &&
	>a &&
	>dir1/a &&
	>dir1/b &&
	>dir1/dir2/a
'

test_expect_success 'status with everything excluded' '
	cat >.git/info/always_exclude <<\EOF &&
*
EOF
	git status -u >standard &&
	git config --local core.gvfs 512 &&
	git status -u >with_hashmap &&
	git config --local core.gvfs 0 &&
	test_cmp standard with_hashmap
'

test_expect_success 'status with some excluded' '
	cat >.git/info/always_exclude <<\EOF &&
*
!/*
EOF
	git status -u >standard &&
	git config --local core.gvfs 512 &&
	git status -u >with_hashmap &&
	git config --local core.gvfs 0 &&
	test_cmp standard with_hashmap
'

test_expect_success 'status with less excluded' '
	cat >.git/info/always_exclude <<\EOF &&
*
!/*
!/dir1
!/dir1/*
EOF
	git status -u >standard &&
	git config --local core.gvfs 512 &&
	git status -u >with_hashmap &&
	git config --local core.gvfs 0 &&
	test_cmp standard with_hashmap
'

test_expect_success 'status with nothing excluded' '
	cat >.git/info/always_exclude <<\EOF &&
*
!/*
!/dir1
!/dir1/*
!/dir1/dir2
!/dir1/dir2/*
EOF
	git status -u >standard &&
	git config --local core.gvfs 512 &&
	git status -u >with_hashmap &&
	git config --local core.gvfs 0 &&
	test_cmp standard with_hashmap
'

test_done
