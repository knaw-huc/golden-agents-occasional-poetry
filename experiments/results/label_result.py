import sys
import pandas as pd

from SPARQLWrapper import SPARQLWrapper, JSON

ENDPOINT = "http://graphdb.localhost/repositories/GA"

QUERY = """
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>

SELECT

    ?uri
    (GROUP_CONCAT(DISTINCT ?label; separator='; ') AS ?labels)
    (GROUP_CONCAT(DISTINCT ?roleType; separator=', ') AS ?roleTypes)
    (GROUP_CONCAT(DISTINCT ?eventType; separator=', ') AS ?eventTypes)

WHERE {
    ?uri roar:participatesIn ?event .

    OPTIONAL { ?uri rdfs:label ?label . }

    OPTIONAL { ?event sem:hasTimeStamp ?timeStamp . }

    ?role a ?roleType ;
          roar:carriedBy ?uri ;
          roar:carriedIn ?event .

    ?event a ?eventType .

    VALUES ?uri {   VALUESHERE   }
} GROUP BY ?uri

"""


def main(infile, outfile):
    if infile.endswith(".csv"):
        df = pd.read_csv(infile)
    elif infile.endswith(".tsv"):
        df = pd.read_csv(infile, sep="\t")

    uris = [f"<{i}>" for i in df["uri"]]
    uris = " ".join(uris)

    query = QUERY.replace("VALUESHERE", uris)

    # Sparql query
    sparql = SPARQLWrapper(ENDPOINT)
    sparql.setQuery(query)
    sparql.setReturnFormat(JSON)
    sparql.setMethod("POST")
    results = sparql.query().convert()

    # Convert to pandas dataframe
    df_results = pd.DataFrame(results["results"]["bindings"])
    df_results = df_results.applymap(lambda x: x["value"] if not pd.isna(x) else "")

    # Merge with original dataframe
    df = df.merge(df_results, on="uri")

    # Write to file
    if outfile.endswith(".csv"):
        df.to_csv(outfile, index=False)
    elif outfile.endswith(".tsv"):
        df.to_csv(outfile, sep="\t", index=False)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 label_result.py <input_file> <output_file>")
        exit()

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    main(input_file, output_file)
