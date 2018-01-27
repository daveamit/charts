#!/bin/bash -xe
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Setup Helm
HELM_URL=https://storage.googleapis.com/kubernetes-helm
HELM_TARBALL=helm-v2.7.2-linux-amd64.tar.gz
STABLE_REPO_URL=https://daveamit.github.io/charts/stable/
INCUBATOR_REPO_URL=https://daveamit.github.io/charts/incubator/
# wget -q ${HELM_URL}/${HELM_TARBALL}
# tar xzfv ${HELM_TARBALL}
# PATH=`pwd`/linux-amd64/:$PATH
# helm init --client-only
# helm repo add stable ${STABLE_REPO_URL}
# helm repo add incubator ${INCUBATOR_REPO_URL}
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/

# Authenticate before uploading to Google Cloud Storage
# cat > sa.json <<EOF
# $SERVICE_ACCOUNT_JSON
# EOF
# gcloud auth activate-service-account --key-file sa.json

# Create the stable repository
STABLE_REPO_DIR=stable-repo
mkdir -p ${STABLE_REPO_DIR}
cd ${STABLE_REPO_DIR}
  helm repo index --url ${STABLE_REPO_URL} .
  for dir in `ls ../stable`;do
    helm dep update ../stable/$dir
    helm dep build ../stable/$dir
    helm package ../stable/$dir
  done
  helm repo index --url ${STABLE_REPO_URL} --merge ./index.yaml .
  # gsutil -m rsync ./ gs://kubernetes-charts/
cd ..
ls -l ${STABLE_REPO_DIR}

# Create the incubator repository
INCUBATOR_REPO_DIR=incubator-repo
mkdir -p ${INCUBATOR_REPO_DIR}
cd ${INCUBATOR_REPO_DIR}
  # gsutil cp gs://kubernetes-charts-incubator/index.yaml .
  helm repo index --url ${INCUBATOR_REPO_URL} .
  for dir in `ls ../incubator`;do
    help dep update ../incubator/$dir
    helm dep build ../incubator/$dir
    helm package ../incubator/$dir
  done
  helm repo index --url ${INCUBATOR_REPO_URL} --merge ./index.yaml .
  # gsutil -m rsync ./ gs://kubernetes-charts-incubator/
cd ..
ls -l ${INCUBATOR_REPO_DIR}

mv ${STABLE_REPO_DIR} /tmp/
mv ${INCUBATOR_REPO_DIR} /tmp/

git reset --hard
git checkout gh-pages
rm -rf stable
rm -rf incubator

mv /tmp/${STABLE_REPO_DIR} ./stable
mv /tmp/${INCUBATOR_REPO_DIR} ./incubator

git config --global user.email "$GH_EMAIL" > /dev/null 2>&1
git config --global user.name "$GH_NAME" > /dev/null 2>&1

git add .
git commit -am 'Updating charts via ci'
git push

