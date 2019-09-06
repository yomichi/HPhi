# This is a pull request, finish.
if [ "_$TRAVIS_PULL_REQUEST" != "_false" ] ;then
  echo "This is a pull request, do nothing."
  exit 0;
fi
# build doc if and only if master, develop, xxx-autodoc, and tag
feature_branch=${TRAVIS_BRANCH%-autodoc}

if [ "_$TRAVIS_BRANCH" == "_master" ]; then
  echo "This is the master branch, deploy docs."
elif [ "_$TRAVIS_BRANCH" == "_develop" ]; then
  echo "This is the develop branch, deploy docs."
elif [ "_${feature_branch}" != "_${TRAVIS_BRANCH}" ]; then
  echo "This is an auto-documented branch, deploy docs."
elif [ -n "$TRAVIS_TAG" ]; then
  echo "This is a versioned tag, deploy docs."
else
  echo "Do nothing."
  exit 0
fi

set -e

sudo apt-get install -y texlive-latex-recommended texlive-latex-extra texlive-lang-japanese texlive-fonts-recommended texlive-fonts-extra latexmk
kanji-config-updmap-sys ipaex
sudo pip install sphinx

openssl aes-256-cbc -K $encrypted_aceb1c042ad9_key -iv $encrypted_aceb1c042ad9_iv -in ${ROOTDIR}/.travis_scripts/id_rsa.enc -out ~/.ssh/id_rsa -d

chmod 600 ~/.ssh/id_rsa
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

git clone git@github.com:${TRAVIS_REPO_SLUG} hphi-doc
cd hphi-doc
mkdir build && cd build
cmake -DDocument=ON ../
make doc

set +e

git checkout gh-pages
if [ ${feature_branch} != ${TRAVIS_BRANCH} ]; then
  cd ${ROOTDIR}/hphi-doc/manual
  mkdir -p $feature_branch && cd $feature_branch
  for lang in ja en; do
    mkdir -p $lang/html
    cp -r ${ROOTDIR}/hphi-doc/build/doc/${lang}/source/html $lang
    git add $lang
  done
elif [ "_${TRAVIS_BRANCH}" == "_develop" ]; then
  cd ${ROOTDIR}/hphi-doc/manual
  mkdir -p develop && cd develop
  for lang in ja en; do
    mkdir -p $lang/html
    cp -r ${ROOTDIR}/hphi-doc/build/doc/${lang}/source/html $lang
    git add $lang
  done
elif [ "_${TRAVIS_BRANCH}" == "_master" ]; then
  cd ${ROOTDIR}/hphi-doc/manual
  mkdir -p master && cd master
  for lang in ja en; do
    mkdir -p $lang/html
    cp -r ${ROOTDIR}/hphi-doc/build/doc/${lang}/source/html $lang
    git add $lang
  done
elif [ -n ${TRAVIS_TAG}]; then
  mkdir -p ${TRAVIS_TAG}
  cp -r ${ROOTDIR}/hphi-doc/* ${TRAVIS_TAG}
  git add ${TRAVIS_TAG}

  cd ${ROOTDIR}/hphi-doc/manual
  mkdir -p ${TRAVIS_TAG} && cd ${TRAVIS_TAG}
  for lang in ja en; do
    mkdir -p $lang/html
    cp -r ${ROOTDIR}/hphi-doc/build/doc/${lang}/source/html $lang
    git add $lang
  done
else
  echo "The deploy script failed to solve where to install documents. The script has some mistake."
  echo "\$TRAVIS_BRANCH: $TRAVIS_BRANCH"
  echo "\$TRAVIS_TAG: $TRAVIS_TAG"
  echo "\$TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST"
  echo "\$feature_branch: $feature_branch"
  exit 1
fi

git config --global user.email "hphi-dev@issp.u-tokyo.ac.jp"
git config --global user.name "HPhi"
git commit -m "Update by TravisCI (\\#${TRAVIS_BUILD_NUMBER})"
ST=$?
if [ $ST == 0 ]; then
  git push origin gh-pages:gh-pages --follow-tags > /dev/null 2>&1
fi

