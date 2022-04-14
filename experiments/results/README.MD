# Experimental results for a range of different threshold and k values.

The `k` parameter governs how many nearest neighbors are found for each entity in the first stage of the algorithm. 
For example, with `k = 10`, then for each entity we find the 10 nearest entities in the embedding, using Euclidean distance.

The threshold parameter denotes a minimum cosine similarity and decides which nearest neighbors are considered candidates for being duplicates. 
For example, of the 10 nearest entities, only 5 may have a cosine similarity larger or equal to the threshold. After this is done, we have obtained a set of candidate pairs. A lower threshold will generally yield more candidate pairs. 

We then further prune candidate pairs by checking them with a set of semantic rules. For example, if each entity corresponds to a non-unique person, we may know that if two persons both occur in the same record, then the entities cannot be duplicates. If a candidate pair violates one of these rules, we remove it.

We can then construct a graph from these candidate pairs, where each node in the graph corresponds to an entity and there exists an edge between two nodes if two entities are a candidate pair. This graph will usually consist of a number of [connected components](https://en.wikipedia.org/wiki/Component_(graph_theory)). These components tend to be larger with lower thresholds.

The threshold parameter is also used in the process of splitting up the components into smaller clusters. During clustering, we subtract the threshold from all computed similarities inside a connected component. We also check for rule violations inside each component. 
Again, smaller thresholds will generally yield larger clusters, and visa versa. Afterwards each cluster is considered to represent a single real life entity.

## Results

Files:
* `ggd_clusters_t0.70_k10.tsv`: 9151 resources in 771 clusters
* `ggd_clusters_t0.80_k10.tsv`: 6788 resources in 2078 clusters
* `ggd_clusters_t0.85_k10.tsv`: 4586 resources in 2816 clusters
* `ggd_clusters_t0.90_k10.tsv`: 1599 resources in 3399 clusters