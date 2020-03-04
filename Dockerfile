FROM ubuntu:19.10

# Update APT and install base packages
RUN set -xe \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils aptitude tzdata locales

# Configure timezone and locale
ENV TZ=Europe/Copenhagen
RUN set -xe \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure --frontend=noninteractive tzdata \
    && sed -i -e 's/# en_DK.UTF-8 UTF-8/en_DK.UTF-8 UTF-8/' /etc/locale.gen \
    && echo 'LANG="en_DK.UTF-8"' > /etc/default/locale \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_DK.UTF-8

ENV LANG en_DK.UTF-8
ENV LANGUAGE en_DK.UTF-8
ENV LC_ALL en_DK.UTF-8

# Unminimize
RUN yes | unminimize

# Install OpenSSH server
RUN set -xe && apt-get install -y openssh-server
# Disallow password when authenticating against SSH

RUN set -xe && sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Install common utilities
RUN set -xe \
    && apt-get install -y adduser bzip2 coreutils curl wget diffutils grep gzip htop man mtr-tiny nano ncdu \
        gnupg1 gnupg apt-transport-https dirmngr ca-certificates lsb-release \
        net-tools p7zip-full tar tmux vim zsh fzy mmv emacs sudo tree glances

# Install developer tools
RUN set -xe \
    && apt-get install -y build-essential git git-extras git-lfs ruby-dev source-highlight python python3 \
    default-jdk jq python-pip python3-pip

# Install .NET Core
RUN set -xe \
    && wget -q https://packages.microsoft.com/config/ubuntu/19.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-3.1 dotnet-sdk-2.1

# Install colorls
RUN set -xe && gem install colorls

# Install lastpass cli
RUN set -xe && apt-get install -y lastpass-cli

# Install speedtest
RUN set -xe \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61 \
    && echo "deb https://ookla.bintray.com/debian bionic main" | tee /etc/apt/sources.list.d/speedtest.list \
    && apt-get update \
    && apt-get install -y speedtest

# Install AWS CLI
RUN set -xe \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && rm awscliv2.zip \
    && ./aws/install \
    && rm -r ./aws

# Install Azure CLI
RUN set -xe \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc \
       | gpg --dearmor \
       | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ disco main" \
       | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y azure-cli

# Install k9s
RUN set -xe \
      && export K9S_URL=`wget -qO- https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.assets[].browser_download_url | select(contains("Linux_x86_64"))'` \ 
      && wget -qO- ${K9S_URL} | tar xvz -C /usr/bin k9s

# Install kotlin
RUN set -xe \
    && mkdir /usr/local/kotlin \
    && export KOTLIN_URL=`wget -qO- https://api.github.com/repos/JetBrains/kotlin/releases/latest | jq -r '.assets[].browser_download_url | select(contains("linux"))'` \
    && export KOTLIN_VERSION=`wget -qO- https://api.github.com/repos/JetBrains/kotlin/releases/latest | jq -r '.tag_name' | sed s/v//` \
    && wget -qO- ${KOTLIN_URL} | tar xvz -C /usr/local/kotlin/ \
    && mv /usr/local/kotlin/kotlin-native-linux-${KOTLIN_VERSION} /usr/local/kotlin/${KOTLIN_VERSION} \
    && ln -s /usr/local/kotlin/${KOTLIN_VERSION} /usr/local/kotlin/current \
    && ln -s -t /usr/local/bin/ /usr/local/kotlin/current/bin/*

# Install kubectl
RUN set -xe \
    && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl

# Install docker ce
RUN set -xe \
    && apt-get install -y gnupg-agent software-properties-common \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Install NodeJS
RUN set -xe \
      && curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash - \
      && apt-get install -y nodejs

# Install exa
RUN set -xe \
      && export EXA_URL=`wget -qO- https://api.github.com/repos/ogham/exa/releases/latest | jq -r '.assets[].browser_download_url | select(contains("linux-x86_64"))'` \
      && wget $EXA_URL -O exa.zip \
      && unzip exa.zip \
      && mv exa-linux-x86_64 /usr/local/bin/exa \
      && rm exa.zip

# Install neovim
RUN set -xe \
      && export NEOVIM_URL=`wget -qO- https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets[].browser_download_url | select(contains("linux64"))'` \
      && wget $NEOVIM_URL -O neovim.tar.gz \
      && tar --strip-components=1 -C /usr -xvf neovim.tar.gz \
      && rm neovim.tar.gz

# Install Go
RUN set -xe \
      && add-apt-repository ppa:longsleep/golang-backports \ 
      && apt update \
      && apt install -y golang-go

# Install node dependencies 
RUN set -xe \
      && npm -g install remark \
      && npm -g install remark-cli \
      && npm -g install remark-stringify \
      && npm -g install remark-frontmatter \
      && npm -g install wcwidth \
      && npm -g install import-js --unsafe \
      && npm -g install neovim \
      && npm -g install typescript

# Install python2.x dependencies
RUN set -xe \
      && pip install flake8 \
      && pip install autoflake \
      && pip install isort \
      && pip install coverage \
      && pip install pynvim \
      && pip install --upgrade msgpack

# Install python3.x dependencies
RUN set -xe \
      && pip3 install pynvim \
      && pip3 install --upgrade msgpack

# Install ruby dependencies
RUN set -xe \
      && gem install neovim

# Configure JAVA_HOME
RUN set -xe \
      && echo "JAVA_HOME=\"`readlink -f $(which java) | sed 's/\/bin\/java//'`\"" >> /etc/environment

# Fix docker login not working
RUN set -xe \
      && apt-get install -y gnupg2 pass

# Add user
RUN set -xe \
    && useradd --create-home --shell /bin/zsh micdah \
    && usermod --append --groups sudo micdah \
    && echo "micdah ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/micdah \
    && chmod 0440 /etc/sudoers.d/micdah

# Create /var/run/sshd to enable OpenSSH to run
RUN set -xe && mkdir /var/run/sshd

# Only allow user to login
RUN set -xe \
    && echo "AllowUsers micdah" >> /etc/ssh/sshd_config

WORKDIR /
EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]
