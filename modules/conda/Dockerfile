FROM amazonlinux:2
RUN yum install -y tar bzip2 

ADD https://micro.mamba.pm/api/micromamba/linux-64/latest /micromamba.tar.bz2
RUN tar -C /opt -jxvf micromamba.tar.bz2 bin/micromamba 
RUN rm -f /micromamba.tar.bz2

COPY build-layer /bin


# FROM mambaorg/micromamba:0.27.0

# RUN micromamba install -y -n base -c conda-forge \
#         bzip2 \
#         conda-pack \
#         conda && \
#     micromamba clean --all --yes
# COPY --chown=$MAMBA_USER:$MAMBA_USER build-layer /opt/conda/bin

CMD ["build-layer"]