FROM mcr.microsoft.com/vscode/devcontainers/python:3.9
# Copy requirements.txt to the container
COPY requirements.txt /tmp/requirements.txt

# Install requirements
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/requirements.txt \
    && rm -rf /tmp/requirements.txt

ENV PATH="/opt/mrtrix3-3.0_RC3/bin:$PATH"
RUN echo "Downloading MRtrix3 ..." \
    && mkdir -p /opt/mrtrix3-3.0_RC3 \
    && curl -fsSL --retry 5 https://dl.dropbox.com/s/2oh339ehcxcf8xf/mrtrix3-3.0_RC3-Linux-centos6.9-x86_64.tar.gz \
    | tar -xz -C /opt/mrtrix3-3.0_RC3 --strip-components 1
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc