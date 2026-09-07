FROM compneurobilbaolab/compneuro-dwiproc:1.0.0

# The upstream image provides MRtrix3, ANTs, FSL, and the scientific Python
# stack. Only the functional LNM dependency missing from that image is added.
COPY requirements.txt /tmp/lnm-requirements.txt
RUN python3 -m pip install \
        --disable-pip-version-check \
        --no-cache-dir \
        -r /tmp/lnm-requirements.txt \
    && rm /tmp/lnm-requirements.txt
