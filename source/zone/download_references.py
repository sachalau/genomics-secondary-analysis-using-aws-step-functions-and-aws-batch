import urllib.request, zipfile, json, io


#Using NCBI API (alpha version), we request the reference genome from taxid 1763 which is the Mycobacterium genus
taxId = 1763
selected_assemblies = []
n=20

with urllib.request.urlopen("https://api.ncbi.nlm.nih.gov/datasets/v1alpha/assembly_descriptors/taxid/" + str(taxId) + "?limit=all&filters.refseq_only=true&returned_content=COMPLETE") as response:
    r = json.loads(response.read())
    for assembly in r["datasets"]:
        try:
            if assembly["assembly_level"]=="Complete Genome" and assembly["assembly_category"] in ["reference genome", "representative genome"]:
                selected_assemblies.append(assembly["assembly_accession"])
        except KeyError:
            pass
        
for entries in [selected_assemblies[i:i + n] for i in range(0, len(selected_assemblies), n)]:
    with urllib.request.urlopen("https://api.ncbi.nlm.nih.gov/datasets/v1alpha/download/assembly_accession/" + "%2C".join(entries) + "?&include_sequence=true&resolve=FULLY_RESOLVED") as assembly_response:
        response = assembly_response.read()
        try:
            z = zipfile.ZipFile(io.BytesIO(response))
            for name in z.namelist():
                if name.endswith(".fna"):
                    filename = name.split("/")[3].split("_genomic")[0] + ".fna"
                    open(filename, "wb").write(z.read(name))
        except zipfile.BadZipFile:
            raise zipfile.BadZipFile("Error in zip file for request " + ",".join(entries) + ", response was : " +  str(response))
            



        
