import os
import sys
from itertools import combinations

import pandas as pd

from rdflib import Graph, URIRef, OWL, BNode, Namespace, RDF, PROV, Literal
from rdflib.resource import Resource
from rdflib.term import skolem_genid

ga = Namespace("https://data.goldenagents.org/datasets/")
voidPlus = Namespace("https://lenticularlens.org/voidPlus/")


def main(infile, outfile):

    # filename without extension
    filename = os.path.basename(infile)
    filename = os.path.splitext(filename)[0]

    # Read in the file
    if infile.endswith(".csv"):
        df = pd.read_csv(infile)
    elif infile.endswith(".tsv"):
        df = pd.read_csv(infile, sep="\t")

    # Group by cluster
    df_grouped = df.groupby("cluster_id")

    g = Graph(identifier=ga.term(f"linksets/{filename}/"))

    # Iterate over each cluster and add to rdflib graph
    for cluster_id, df_cluster in df_grouped:
        uris = df_cluster["uri"]

        # Better explicit, so take combinations
        combs = combinations(uris, 2)

        for r1, r2 in combs:
            g.add((URIRef(r1), OWL.sameAs, URIRef(r2)))

            # Bit of reification
            statement = Resource(g, BNode())
            statement.add(RDF.type, RDF.Statement)
            statement.add(RDF.subject, URIRef(r1))
            statement.add(RDF.predicate, OWL.sameAs)
            statement.add(RDF.object, URIRef(r2))

            statement.add(PROV.wasDerivedFrom, Literal(infile))
            statement.add(voidPlus.hasClusterID, Literal(cluster_id))

    # Skolemize
    g = skolemize(g)

    # Bind NS
    g.bind("ga", ga)
    g.bind("voidPlus", voidPlus)

    # Write to file
    g.serialize(outfile, format="trig")


def skolemize(g):

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
