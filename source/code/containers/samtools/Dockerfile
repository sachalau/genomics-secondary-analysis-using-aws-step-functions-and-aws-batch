FROM quay.io/biocontainers/samtools:1.9--h10a08f8_12

ARG VERSION=1.9

# Metadata
LABEL container.base.image="ubuntu:18.04"
LABEL software.name="SAMtools"
LABEL software.version=${VERSION}
LABEL software.description="Utilities for the Sequence Alignment/Map (SAM/BAM/CRAM) formats"
LABEL software.website="http://www.htslib.org"
LABEL software.documentation="http://www.htslib.org/doc/samtools.html"
LABEL software.license="MIT/Expat"
LABEL tags="Genomics"

ENTRYPOINT ["samtools"]
