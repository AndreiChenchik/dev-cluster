FROM mcr.microsoft.com/vscode/devcontainers/python:0-3.9-bullseye

# Prepare for Go
ENV GOROOT=/usr/local/go \
    GOPATH=/go
ENV PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}

# Install gh docker-ce docker-ce-cli containerd.io kubectl helm google-cloud-sdk
RUN apt-get update \
    && apt-get -y install --no-install-recommends ca-certificates curl gnupg lsb-release apt-transport-https \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && curl https://baltocdn.com/helm/signing.asc | apt-key add - \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends gh docker-ce docker-ce-cli containerd.io kubectl helm google-cloud-sdk \
    && bash -c "$(curl -fsSL "https://raw.githubusercontent.com/microsoft/vscode-dev-containers/main/script-library/go-debian.sh")" \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Node
RUN su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install "lts/*" 2>&1"

RUN mkdir /workplace && chown vscode /workplace

# Install poetry
USER vscode
RUN curl -sSL \
  https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py \
  | python -

# Install 1Password
RUN mkdir /home/vscode/scripts \
  && curl -sL https://cache.agilebits.com/dist/1P/op/pkg/v1.12.3/op_linux_arm64_v1.12.3.zip -o /home/vscode/op.zip \
  && unzip -j /home/vscode/op.zip "op" -d "/home/vscode/scripts"
# Set profile values
RUN echo "source /home/vscode/1penv.sh" >> /home/vscode/.bashrc \
  && echo 'export PATH=$HOME/.poetry/bin:$PATH' >> /home/vscode/.bashrc \
  && echo 'export PATH=$PATH:$HOME/scripts' >> /home/vscode/.bashrc \
  && echo "export ENVINJ_SKIP=\"export 1penv\"" >> /home/vscode/.bashrc \
  && echo "export ENVINJ_APPS=\"uvicorn alembic\"" >> /home/vscode/.bashrc \
  && echo 'export ENVINJ_PROVIDER='\''1penv $1'\' >> /home/vscode/.bashrc \
  && echo "source /home/vscode/env-injector/activate.sh" >> /home/vscode/.bashrc \
  && echo 'export POETRY_CACHE_DIR=/workspace/poetry' >> /home/vscode/.bashrc

# 1Password config
RUN mkdir -p /home/vscode/.config/op && chmod 700 /home/vscode/.config/op && echo "hello" > /home/vscode/.config/op/config

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1