#ifndef VIRTUALPROJECTION_H
#define VIRTUALPROJECTION_H


/*
 * Both sparse checkout and virtual projection can be used together. Any file
 * is only considered "included" if it is found in both the virtual projection
 * and in the sparse-checkout file.
 */

void apply_virtualprojection(struct index_state *istate);

/*
 * Check the virtual projection hashmap and return 1 for found, 0 for not
 * found and -1 for undecided.
 */
int is_virtualprojection(const char *pathname, int pathlen);

/*
 * Free the virtual projection data structures.
 */
void free_virtualprojection(void);

#endif
