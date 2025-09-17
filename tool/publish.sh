#!/bin/bash

# Publishes the packages for a release to isar-community.dev using the artifacts from github
# Prerequisite: unpub authenticated and token added:
# `unpub_auth login && unpub_auth get | dart pub token add https://pub.isar-community.dev/`
#

set -o errexit
pushd packages/isar_plus
dart pub get
popd
sh tool/download_binaries.sh
#dart pub token add --env-var=PUB_JSON https://pub.isar-community.dev/
pushd packages/isar_plus
dart pub publish --force
popd
pushd packages/isar_community_generator
dart pub publish --force
popd
pushd packages/isar_community_flutter_libs
dart pub publish --force
popd

