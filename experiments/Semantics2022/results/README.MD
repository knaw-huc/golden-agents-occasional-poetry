# Experimental results for a range of different threshold and k values.

The `k` parameter governs how many nearest neighbors are found for each entity in the first stage of the algorithm. 
For example, with `k = 10`, then for each entity we find the 10 nearest entities in the embedding, using Euclidean distance.

The threshold parameter denotes a minimum cosine similarity and decides which nearest neighbors are considered candidates for being duplicates. 
For example, of the 10 nearest entities, only 5 may have a cosine similarity larger or equal to the threshold. After this is done, we have obtained a set of candidate pairs. A lower threshold will generally yield more candidate pairs. 

We then further prune candidate pairs by checking them with a set of semantic rules. For example, if each entity corresponds to a non-unique person, we may know that if two persons both occur in the same record, then the entities cannot be duplicates. If a candidate pair violates one of these rules, we remove it.

We can then construct a graph from these candidate pairs, where each node in the graph corresponds to an entity and there exists an edge between two nodes if two entities are a candidate pair. This graph will usually consist of a number of [connected components](https://en.wikipedia.org/wiki/Component_(graph_theory)). These components tend to be larger with lower thresholds.

The threshold parameter is also used in the process of splitting up the components into smaller clusters. During clustering, we subtract the threshold from all computed similarities inside a connected component. We also check for rule violations inside each component. 
Again, smaller thresholds will generally yield larger clusters, and visa versa. Afterwards each cluster is considered to represent a single real life entity.

## Scripts

This folder contains two scripts:

* `label_result.py` that is used to label the results of the experiment with additional meta data, such as the name of the person, the roles in which he/she occurs, the type of event, and the event date. This is run before the validation step and helps the user to understand and validate the result.
* `make_linkset.py` that transforms a file into an RDF-linkset. We run this script after the validation step on the validated file. It can also be used on the other files, if wanted, then all resources are included. 

## Results

Files:
* `ggd_clusters_t0.70_k10.tsv`: 9151 resources in 3399 clusters
* `ggd_clusters_t0.80_k10.tsv`: 6788 resources in 2816 clusters
* `ggd_clusters_t0.85_k10.tsv`: 4586 resources in 2078 clusters
* `ggd_clusters_t0.90_k10.tsv`: 1599 resources in 771 clusters

## Validation

The `ggd_clusters_t0.70_k10.tsv` file was manually validated and the result is given in `ggd_clusters_t0.70_k10_validation.tsv`. It includes two extra columns:
* `valid`: TRUE or FALSE depending on whether the resource is rightfully in this cluster
* `comments`: for additional information on a record or entity

From this file a RDF-linkset was generated using the `make_linkset.py` script: `ggd_clusters_t0.70_k10_validation.trig`. Only the resources that have `valid = TRUE` are included in the linkset. The `owl:sameAs` predicate is used to link the resources together and an extra `rdf:Statement` resource is added for each link to indicate the clusterId (cf. the [VoiD+ vocabulary](https://lenticularlens.org/docs/03.Ontology/#4-void-documentation). )