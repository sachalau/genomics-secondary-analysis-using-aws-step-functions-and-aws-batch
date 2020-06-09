FROM quay.io/biocontainers/kraken:1.1.1--pl526hc9558a2_4 AS build

ARG VERSION=1.1.1--pl526hc9558a2_4 

LABEL container.base.image="quay.io/biocontainer/kraken:1.1.1--pl526hc9558a2_4"
LABEL software.name="kraken"
LABEL software.version=${VERSION}
LABEL software.description="kraken metagenomics analyser"
LABEL software.website="http://www.htslib.org"
LABEL software.documentation="http://www.htslib.org/doc/samtools.html"
LABEL software.license="MIT/Expat"
LABEL tags="Genomics"

FROM quay.io/biocontainers/kraken:1.1.1--pl526hc9558a2_4 AS final

ENTRYPOINT ["kraken"]

