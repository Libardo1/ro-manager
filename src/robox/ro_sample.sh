#!/bin/bash
#
# RO manager sample script
#

./ro config -v \
  -b test/robase \
  -r http://calatola.man.poznan.pl/robox/dropbox_accounts/1/ro_containers/2 \
  -n "Test user" \
  -p "d41d8cd98f00b204e9800998ecf8427e" \
  -e "testuser@example.org"

mkdir test/robase/test-create-RO
cp -r test/data/ro-test-1/* test/robase/test-create-RO

./ro create -v "Test Create RO" -d test/robase/test-create-RO -i RO-id-testCreate

#cd test/robase/test-create-RO
#../../../ro status -v
#cd ../../..

./ro status -v -d test/robase/test-create-RO

./ro list -v -d test/robase/test-create-RO

./ro annotate -v test/robase/test-create-RO/subdir1/subdir1-file.txt title "subdir1-file.txt title"

./ro annotate -v test/robase/test-create-RO/subdir2/subdir2-file.txt title "subdir2-file.txt title"

# End.
