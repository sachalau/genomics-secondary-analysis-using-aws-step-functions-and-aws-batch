FROM quay.io/biocontainers/bcftools:1.9--h68d8f2e_9

ARG VERSION=1.9

# Metadata
LABEL container.base.image="ubuntu:18.04"
LABEL software.name="BCFtools"
LABEL software.version=${VERSION}
LABEL software.description="Utilities for variant calling and manipulating files in the Variant Call Format (VCF) and its binary counterpart BCF"
LABEL software.website="http://www.htslib.org"
LABEL software.documentation="http://www.htslib.org/doc/bcftools.html"
LABEL software.license="MIT/Expat"
LABEL tags="Genomics"

ENTRYPOINT ["bcftools"]
