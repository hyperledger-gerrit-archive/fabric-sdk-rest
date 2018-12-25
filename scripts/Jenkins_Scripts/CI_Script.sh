#!/bin/bash -e
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

Parse_Arguments() {
      while [ $# -gt 0 ]; do
              case $1 in
                      --env_Info)
                            env_Info
                            ;;
                      --clean_Environment)
                            clean_Environment
                            ;;
                      --sdk_Rest_Tests)
                            sdk_Rest_Tests
                            ;;
              esac
              shift
      done
}

clean_Environment() {

echo "-----------> Clean Docker Containers & Images, unused/lefover build artifacts"

function clearContainers () {
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS || true
        fi
}

function removeUnwantedImages() {

        for i in $(docker images | grep none | awk '{print $3}'); do
                docker rmi ${i};
        done

        for i in $(docker images | grep -vE ".*baseimage.*(0.4.13|0.4.14)" | grep -vE ".*baseos.*(0.4.13|0.4.14)" | grep -vE ".*couchdb.*(0.4.13|0.4.14)" | grep -vE ".*zoo.*(0.4.13|0.4.14)" | grep -vE ".*kafka.*(0.4.13|0.4.14)" | grep -v "REPOSITORY" | awk '{print $1":" $2}'); do
                docker rmi ${i};
        done
}

# Delete nvm prefix & then delete nvm
rm -rf $HOME/.nvm/ $HOME/.node-gyp/ $HOME/.npm/ $HOME/.npmrc  || true

mkdir $HOME/.nvm || true

# remove tmp/hfc and hfc-key-store data
rm -rf /home/jenkins/.nvm /home/jenkins/npm /tmp/fabric-shim /tmp/hfc* /tmp/npm* /home/jenkins/kvsTemp /home/jenkins/.hfc-key-store

rm -rf /var/hyperledger/*

rm -rf gopath/src/github.com/hyperledger/fabric-ca/vendor/github.com/cloudflare/cfssl/vendor/github.com/cloudflare/cfssl_trust/ca-bundle || true
# yamllint disable-line rule:line-length
rm -rf gopath/src/github.com/hyperledger/fabric-ca/vendor/github.com/cloudflare/cfssl/vendor/github.com/cloudflare/cfssl_trust/intermediate_ca || true

clearContainers
removeUnwantedImages
}

env_Info() {
        # This function prints system info

        #### Build Env INFO
        echo -e "\033[32m -----------> Build Env INFO" "\033[0m"
        # Output all information about the Jenkins environment
        uname -a
        cat /etc/*-release
        env
        gcc --version
        docker version
        docker info
        docker-compose version
        pgrep -a docker
}

install_Npm() {

	echo "-------> ARCH:" $ARCH
	# Install nvm to install multi node versions
	wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
	# shellcheck source=/dev/null
	export NVM_DIR="$HOME/.nvm"
	# shellcheck source=/dev/null
	[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
	echo "------> Install NodeJS"
	# Install NODE_VER
	echo "------> Use $NODE_VER"
	nvm install $NODE_VER || true
	nvm use --delete-prefix v$NODE_VER --silent
	npm install loopback-connector-fabric && npm install fabric-rest

	echo -e "\033[32m npm version ------> $(npm -v)" "\033[0m"
	echo -e "\033[32m node version ------> $(node -v)" "\033[0m"

}

# run sdk e2e tests
sdk_Rest_Tests() {

        cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-rest/packages

        # Install node, npm before start the tests
        install_Npm
        cd ..
        npm install
        # Run the fabric-sdk-rest tests
        ./tests/fullRun.sh
}

Parse_Arguments $@
