FROM quay.io/biocontainers/freebayes:1.3.2--py36h89e4507_1

ARG VERSION=1.3.2

LABEL container.base.image="quay.io/biocontainers/freebayes:1.3.2--py36h89e4507_1"
LABEL software.name="freebayes"
LABEL software.version=${VERSION}
LABEL software.description="freebayes genotyper from BAM/CRAM files"
LABEL software.website="http://www.htslib.org"
LABEL software.documentation="http://www.htslib.org/doc/samtools.html"
LABEL software.license="MIT/Expat"
LABEL tags="Genomics"

ENTRYPOINT ["freebayes"]

