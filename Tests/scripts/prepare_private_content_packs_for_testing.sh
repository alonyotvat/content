#!/usr/bin/env bash

# exit on errors
set -e

GIT_BRANCH=${REPO_BRANCH:-unknown}
GITHUB_RUN_NUMBER=${GITHUB_RUN_NUMBER:-00000}
CIRCLE_ARTIFACTS=${CIRCLE_ARTIFACTS}
PACK_ARTIFACTS=$CIRCLE_ARTIFACTS/content_packs.zip
ID_SET=$CIRCLE_ARTIFACTS/id_set.json
EXTRACT_FOLDER=$(mktemp -d)

if [[ -z "$GCS_MARKET_KEY" ]]; then
    echo "GCS_MARKET_KEY not set aborting!"
    exit 1
fi

echo "Preparing content packs for testing ..."

KF=$(mktemp)
echo "$GCS_MARKET_KEY" > "$KF"
gcloud auth activate-service-account --key-file="$KF" > auth.out 2>&1
echo "Auth loaded successfully."

GCS_MARKET_BUCKET="marketplace-dist"
GCS_BUILD_BUCKET="marketplace-ci-build-private"


GCS_PRIVATE_TESTING_BUCKET="marketplace-ci-build-private"
GCS_PRIVATE_PROD_BUCKET="marketplace-dist-private"
GCS_TESTING_BUCKET="marketplace-ci-build"
GCS_PUBLIC_PROD_BUCKET="marketplace-dist"
SOURCE_PATH="content/packs"

PRIVATE_BUILD_BUCKET_PATH="content/builds/$GIT_BRANCH/$GITHUB_RUN_NUMBER"
PRIVATE_TARGET_PATH="$PRIVATE_BUILD_BUCKET_PATH/content/packs"
BUCKET_FULL_TARGET_PATH="$GCS_PRIVATE_TESTING_BUCKET/$PRIVATE_BUILD_BUCKET_PATH"

echo "Copying private master files at: $SOURCE_PATH to target path: gs://$GCS_PRIVATE_TESTING_BUCKET/$PRIVATE_TARGET_PATH ..."
gsutil -m cp -r "gs://$GCS_PRIVATE_PROD_BUCKET/$SOURCE_PATH" "gs://$GCS_PRIVATE_TESTING_BUCKET/$PRIVATE_TARGET_PATH"
echo "Finished copying private bucket successfully."


PUBLIC_BUILD_BUCKET_PATH="content/builds/$GIT_BRANCH/$GITHUB_RUN_NUMBER"
PUBLIC_TARGET_PATH="$PUBLIC_BUILD_BUCKET_PATH/content/packs"
BUCKET_FULL_TARGET_PATH="$GCS_TESTING_BUCKET/$PUBLIC_BUILD_BUCKET_PATH"

echo "Copying public master files at: $SOURCE_PATH to target path: gs://$GCS_TESTING_BUCKET/$PUBLIC_TARGET_PATH ..."
gsutil -m cp -r "gs://$GCS_PUBLIC_PROD_BUCKET/$SOURCE_PATH" "gs://$GCS_TESTING_BUCKET/$PUBLIC_TARGET_PATH"
echo "Finished copying public bucket successfully."

echo "Updating modified content packs in the bucket ..."

#if [ ! -n "${NIGHTLY}" ]; then
#  CONTENT_PACKS_TO_INSTALL_FILE="./Tests/content_packs_to_install.txt"
#  if [ ! -f $CONTENT_PACKS_TO_INSTALL_FILE ]; then
#    echo "Could not find file $CONTENT_PACKS_TO_INSTALL_FILE."
#  else
#    CONTENT_PACKS_TO_INSTALL=$(paste -sd, $CONTENT_PACKS_TO_INSTALL_FILE)
#    if [[ -z "$CONTENT_PACKS_TO_INSTALL" ]]; then
#      echo "Did not get content packs to update in the bucket."
#    else
#      echo "Updating the following content packs: $CONTENT_PACKS_TO_INSTALL ..."
#      python3 ./Tests/Marketplace/upload_packs.py -a $PACK_ARTIFACTS -d $CIRCLE_ARTIFACTS/packs_dependencies.json -e $EXTRACT_FOLDER -b $GCS_BUILD_BUCKET -pb $GCS_BUILD_BUCKET -s $KF -n $GITHUB_RUN_NUMBER -p $CONTENT_PACKS_TO_INSTALL -o -sb $TARGET_PATH -k $PACK_SIGN_KEY -rt false --id_set_path $ID_SET -pr True
#      echo "Finished updating content packs successfully."
#    fi
#  fi
#else
#  echo "Updating all content packs for nightly build..."
#  python3 ./Tests/Marketplace/upload_packs.py -a $PACK_ARTIFACTS -d $CIRCLE_ARTIFACTS/packs_dependencies.json -e $EXTRACT_FOLDER -b $GCS_BUILD_BUCKET -pb $GCS_BUILD_BUCKET -s $KF -n $GITHUB_RUN_NUMBER -sb $TARGET_PATH -k $PACK_SIGN_KEY -rt false --id_set_path $ID_SET -pr True -o
#  echo "Finished updating content packs successfully."
#fi

#echo "Normalizing images paths to build bucket ..."
#python3 ./Tests/Marketplace/normalize_gcs_paths.py -sb $TARGET_PATH -b $GCS_BUILD_BUCKET -s $KF
#echo "Finished normalizing images paths successfully."

echo -e "\nBrowse to the build bucket with this address:"
echo -e "https://console.cloud.google.com/storage/browser/$BUCKET_FULL_TARGET_PATH\n"
echo "Finished preparing content packs for testing successfully."

echo -e "\nIf you want to connect this build bucket to your test machine, add this server config:"
echo "marketplace.bootstrap.bypass.url: https://storage.googleapis.com/$BUCKET_FULL_TARGET_PATH"