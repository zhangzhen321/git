#include "cache.h"
#include "hashmap.h"
#include "run-command.h"
#include "virtualprojection.h"

#define HOOK_INTERFACE_VERSION	(1)

static struct strbuf virtual_projection_data = STRBUF_INIT;

static void load_virtualProjection()
{
	struct child_process cp = CHILD_PROCESS_INIT;
	char ver[64];
	const char *argv[3];
	int err;

	strbuf_init(&virtual_projection_data, 0);

	snprintf(ver, sizeof(ver), "%d", HOOK_INTERFACE_VERSION);
	argv[0] = core_virtualprojection;
	argv[1] = ver;
	argv[2] = NULL;
	cp.argv = argv;
	cp.use_shell = 1;

	err = capture_command(&cp, &virtual_projection_data, 1024);
	if (err)
		die("unable to load virtual projection");
}

struct virtualprojection {
	/* This must be the first element for hashmaps to work */
	struct hashmap_entry ent;
	const char *pattern;
	int patternlen;
};

static unsigned int(*vphash)(const void *buf, size_t len);
static int(*vpcmp)(const char *a, const char *b, size_t len);

static int vp_hashmap_cmp(const void *unused_cmp_data,
	const void *a, const void *b, const void *key)
{
	const struct virtualprojection *vp1 = a;
	const struct virtualprojection *vp2 = b;

	return vpcmp(vp1->pattern, vp2->pattern, vp1->patternlen);
}

static void vp_hashmap_add(struct hashmap *map, const char *pattern, const int patternlen)
{
	struct virtualprojection *vp;

	vp = xmalloc(sizeof(struct virtualprojection));
	hashmap_entry_init(vp, vphash(pattern, patternlen));
	vp->pattern = pattern;
	vp->patternlen = patternlen;
	hashmap_add(map, vp);
}

static void vp_mark_skip_worktree(struct hashmap *map, struct cache_entry *ce)
{
	static struct strbuf sb = STRBUF_INIT;
	struct virtualprojection vp;
	char *slash;

	/*
	 * turn on skip worktree for all entries _except_ those
	 * in the virtual projection
	 */
	ce->ce_flags |= CE_SKIP_WORKTREE;

	/* Check straight mapping */
	strbuf_reset(&sb);
	strbuf_addch(&sb, '/');
	strbuf_add(&sb, ce->name, ce->ce_namelen);
	hashmap_entry_init(&vp, vphash(sb.buf, sb.len));
	vp.pattern = sb.buf;
	vp.patternlen = sb.len;
	if (hashmap_get(map, &vp, NULL)) {
		ce->ce_flags &= ~CE_SKIP_WORKTREE;
		return;
	}

	/*
	 * Check to see if it matches a directory or any path
	 * underneath it.  In other words, /foo/ will match a
	 * directory /foo and all paths underneath it.
	 */
	strbuf_reset(&sb);
	strbuf_addch(&sb, '/');
	slash = strrchr(ce->name, '/');
	if (slash)
		strbuf_add(&sb, ce->name, slash - ce->name + 1);
	while (sb.len) {
		hashmap_entry_init(&vp, vphash(sb.buf, sb.len));
		vp.pattern = sb.buf;
		vp.patternlen = sb.len;
		if (hashmap_get(map, &vp, NULL))
		{
			ce->ce_flags &= ~CE_SKIP_WORKTREE;
			return;
		}

		slash = strrchr(sb.buf, '/');
		strbuf_setlen(&sb, slash ? slash - sb.buf : 0);
	}

	/* check for shell globs with no wild cards (.gitignore, .gitattributes) */
	strbuf_reset(&sb);
	slash = strrchr(ce->name, '/');
	if (slash)
		strbuf_addstr(&sb, slash + 1);
	else
		strbuf_add(&sb, ce->name, ce->ce_namelen);
	hashmap_entry_init(&vp, vphash(sb.buf, sb.len));
	vp.pattern = sb.buf;
	vp.patternlen = sb.len;
	if (hashmap_get(map, &vp, NULL))
		ce->ce_flags &= ~CE_SKIP_WORKTREE;
}

void apply_virtualprojection(struct index_state *istate)
{
	struct hashmap map;
	char *buf, *entry;
	size_t len;
	int i;

	if (!git_config_get_virtualprojection())
		return;

	if (!virtual_projection_data.len)
		load_virtualProjection();

	/* 
	 * Build a hashmap of the virtual projection data we can use to look match
	 * for cache entry matches quickly 
	 */
	vphash = ignore_case ? memihash : memhash;
	vpcmp = ignore_case ? strncasecmp : strncmp;
	hashmap_init(&map, vp_hashmap_cmp, NULL, 0);

	entry = buf = virtual_projection_data.buf;
	len = virtual_projection_data.len;
	for (i = 0; i < len; i++) {
		if (buf[i] == '\0') {
			vp_hashmap_add(&map, entry, buf + i - entry);
			entry = buf + i + 1;
		}
	}

	/* set skip_worktree bit based on virtual projection data */
	for (i = 0; i < istate->cache_nr; i++)
		vp_mark_skip_worktree(&map, istate->cache[i]);

	hashmap_free(&map, 1);
}
