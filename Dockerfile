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
        neovim net-tools p7zip-full tar tmux vim zsh fzy mmv emacs sudo tree 

# Install developer tools
RUN set -xe \
    && apt-get install -y build-essential git git-extras git-lfs ruby-dev source-highlight python python3 default-jdk

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
RUN set -xe && wget -qO- https://github.com/derailed/k9s/releases/download/v0.17.0/k9s_Linux_x86_64.tar.gz | tar xvz -C /usr/bin k9s

# Install kotlin
ARG KOTLIN_VERSION=1.3.61
RUN set -xe \
    && mkdir /usr/local/kotlin \
    && wget -qO- https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/kotlin-native-linux-$KOTLIN_VERSION.tar.gz \
       | tar xvz -C /usr/local/kotlin/ \
    && mv /usr/local/kotlin/kotlin-native-linux-$KOTLIN_VERSION /usr/local/kotlin/$KOTLIN_VERSION \
    && ln -s /usr/local/kotlin/$KOTLIN_VERSION /usr/local/kotlin/current \
    && ln -s -t /usr/local/bin/ /usr/local/kotlin/current/bin/*

# Install kubectl
RUN set -xe \
    && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl

# Add user
ARG USER=micdah
RUN set -xe \
    && useradd --create-home --shell /bin/zsh $USER \
    && usermod --append --groups sudo $USER \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

# Create /var/run/sshd to enable OpenSSH to run
RUN set -xe && mkdir /var/run/sshd

# Only allow user to login
RUN set -xe \
    && echo "AllowUsers $USER" >> /etc/ssh/sshd_config

WORKDIR /
EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]
