import os
import sys
from itertools import combinations

import pandas as pd

from rdflib import Graph, URIRef, OWL, BNode, Namespace, RDF, PROV, Literal
from rdflib.resource import Resource
from rdflib.term import skolem_genid

ga = Namespace("https://data.goldenagents.org/datasets/")
voidPlus = Namespace("https://lenticularlens.org/voidPlus/")


def main(infile: str, outfile: str, reification: bool = True):
    """
    Create a (reified) linkset from a GraphEmbeddings result.

    This function takes in a GraphEmbeddings result and creates a owl:sameAs
    linkset from its clusters. Per cluster, it outputs a owl:sameAs triple
    for all the combinations of the resources in this cluster. Skolemized
    blank nodes are used as resource identifiers for the rdf:Statement.

    If the file is validated (i.e. there is a column named 'valid'), then
    the linkset is only created for the valid resources in clusters.

    Example:
        ```ttl
        <https://archief.amsterdam/indexen/deeds/9d6d21e3-0133-666d-e053-b784100a1840?person=4d0a5597-9b56-7040-e053-b784100a6264> owl:sameAs <https://archief.amsterdam/indexen/deeds/a3cb51cc-b18e-50ee-e053-b784100a6caf?person=d4b2498e-8470-6faf-0510-0c935c356c0a> .

        <https://data.goldenagents.org/.well-known/genid/N0000963728874509a598be4915758992> a rdf:Statement ;
            rdf:object <https://archief.amsterdam/indexen/deeds/a3cb51cc-b18e-50ee-e053-b784100a6caf?person=d4b2498e-8470-6faf-0510-0c935c356c0a> ;
            rdf:predicate owl:sameAs ;
            rdf:subject <https://archief.amsterdam/indexen/deeds/9d6d21e3-0133-666d-e053-b784100a1840?person=4d0a5597-9b56-7040-e053-b784100a6264> ;
            prov:wasDerivedFrom "ggd_clusters_t0.70_k10_validation.tsv" ;
            voidPlus:hasClusterID 3469 ;
            voidPlus:hasValidation <https://data.goldenagents.org/.well-known/genid/Nb786c65b22bc413bb3a8629b5e79a9ba> .

        <https://data.goldenagents.org/.well-known/genid/Nb786c65b22bc413bb3a8629b5e79a9ba> a voidPlus:Validation ;
            voidPlus:hasValidationStatus <https://lenticularlens.org/voidPlus/resource/Accepted> .
        ```

    Args:
        infile (str): path to the csv/tsv file
        outfile (str): path to the output file (.trig)
        reification (bool): wether or not to reify the link using an rdf:Statement (default: True)

    """

    # filename without extension
    filename = os.path.basename(infile)
    filename = os.path.splitext(filename)[0]

    # Read in the file
    if infile.endswith(".csv"):
        df = pd.read_csv(infile)
    elif infile.endswith(".tsv"):
        df = pd.read_csv(infile, sep="\t")

    # Check validation status
    if "valid" in df.columns:
        VALIDATION = True
        df = df[df["valid"] == True]  # only keep valid rows
    else:
        VALIDATION = False

    # Group by cluster
    df_grouped = df.groupby("cluster_id")

    g = Graph(identifier=ga.term(f"linksets/{filename}/"))

    # Iterate over each cluster and add to rdflib graph
    for cluster_id, df_cluster in df_grouped:
        uris = df_cluster["uri"]

        # Due to validation, there could be a cluster of one URI
        if len(uris) == 1:
            continue

        # Better explicit, so take combinations
        combs = combinations(uris, 2)

        for r1, r2 in combs:
            g.add((URIRef(r1), OWL.sameAs, URIRef(r2)))

            if reification:
                # Bit of reification
                statement = Resource(g, BNode())
                statement.add(RDF.type, RDF.Statement)
                statement.add(RDF.subject, URIRef(r1))
                statement.add(RDF.predicate, OWL.sameAs)
                statement.add(RDF.object, URIRef(r2))

                statement.add(PROV.wasDerivedFrom, Literal(infile))
                statement.add(voidPlus.hasClusterID, Literal(cluster_id))

                if VALIDATION:  # only for the valid links
                    validationStatus = Resource(g, BNode())
                    validationStatus.add(RDF.type, voidPlus.Validation)
                    validationStatus.add(
                        voidPlus.hasValidationStatus,
                        URIRef("https://lenticularlens.org/voidPlus/resource/Accepted"),
                    )

                    statement.add(voidPlus.hasValidation, validationStatus)

    # Skolemize
    g = skolemize(g)

    # Bind NS
    g.bind("ga", ga)
    g.bind("voidPlus", voidPlus)

    # Write to file
    g.serialize(outfile, format="trig")


def skolemize(g):
    """
    Skolemize all blank node identifiers into .well-known URIs because we don't like blank nodes.
    """

    new_g = Graph(identifier=g.identifier)
    g = g.skolemize(new_graph=new_g, authority=ga, basepath=skolem_genid)

    return g


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 make_linkset.py <input_file> <output_file>")
        exit()

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    main(input_file, output_file)
