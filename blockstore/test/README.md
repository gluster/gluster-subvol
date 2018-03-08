# Script sanity tests

This directory contains tests that help sanitize the various scripts.

## Tests available

- test-flex-volume.sh: This is used to test functionality of
`../flex-volume/glfs-block-subvol` script
- ansible/test-recycler.yml: This is used to test functionality of
`../pv-recycler-pod/<dockerimage>`

## Testing glfs-flex-volume

Test script test-flex-volume.sh is written to test the script
`../flex-volume/glfs-block-subvol`.

The test assumes that a gluster volume is setup and the `../creator/creator.sh`
script has been executed to create at least 2 backing files.

To run the tests, execute the following command from the subdirectory containing
the script, `./test-flex-volume.sh "127.0.0.1:127.0.0.1" patchy`

# Testing pv-recycler-pod

The ansible playplaybool ansible/test-recycler.yml helps test the pod image
created for the recycler.

The test requires that a k8s setup is running and that the inventory file for
the ansible play has the k8s master listed under the `master` group.

Further, the test-recycler.yml has a few variables defined, that help test the
recycler. Of note are,
- gluster_subvol.accessmode: <ReadWriteOnce/ReadWriteMany> Based on the storage
class being tested.
- gluster_subvol.storageclass: <name> Name of the storage class to test.
- gluster-block-subvol.maxinstances: <number> Number of PVs to scale upto in the
tests. These PVs should already be imported into the k8s setup.
- kube_setup.kubeconfig: <path_to_k8s_admin.conf>

To run the tests use: ansible-playbook -i <inventory file> ./test-recycler.yml

If the setup was created using Vagrant use:
ansible-playbook -i <path_to_directory_containing_vagrant_file>/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory ./test-recycler.yml
