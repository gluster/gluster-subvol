# Script sanity tests

This directory contains tests that help sanitize the various scripts.

## Tests available

- test-flex-volume.sh: This is used to test functionality of
`../flex-volume/glfs-block-subvol` script

## Testing glfs-flex-volume

Test script test-flex-volume.sh is written to test the script
`../flex-volume/glfs-block-subvol`.

The test assumes that a gluster volume is setup and the `../creator/creator.sh`
script has been executed to create at least 2 backing files.

To run the tests, execute the following command from the subdirectory containing
the script, `./test-flex-volume.sh "127.0.0.1:127.0.0.1" patchy`
