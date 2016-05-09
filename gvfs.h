#ifndef GVFS_H
#define GVFS_H

#include "cache.h"


/*
 * This file is for the specific settings and methods
 * used for GVFS functionality
 */


/*
 * The list of bits in the core_gvfs setting
 */
#define GVFS_SKIP_SHA_ON_INDEX_READ 1


static inline BOOL gvfs_config_is_set(int mask) {
	return (core_gvfs & mask) == mask;
}

static inline BOOL gvfs_config_is_set_any() {
	return core_gvfs > 0;
}

static inline BOOL gvfs_config_load_and_is_set(int mask) {
	git_config_get_int("core.gvfs", &core_gvfs);
	return gvfs_config_is_set(mask);
}


#endif /* GVFS_H */