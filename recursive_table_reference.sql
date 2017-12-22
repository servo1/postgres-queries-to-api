-- This recurses through schema/table/view relationships and turns them into a graph like form 
-- make it quite easy to generate queries and join statements
-- depends on v_defr and v_defrels found in this repo
-- Materialized View: public.vm_rrels

-- DROP MATERIALIZED VIEW public.vm_rrels;

CREATE MATERIALIZED VIEW public.vm_rrels AS 
 WITH RECURSIVE rels(obj, schems, objs, clmns, dirxn, path, depth) AS (
         SELECT v_defr.tbl,
            ARRAY[v_defr.schem::text] AS schems,
            ARRAY[v_defr.tbl::text] AS objs,
            ARRAY['id'::text] AS clmns,
            ARRAY['s'::text] AS dirxn,
            ARRAY[ARRAY['id'::text, v_defr.tbl::text]] AS path,
            1 AS depth
           FROM v_defr
          GROUP BY v_defr.schem, v_defr.tbl
        UNION
         SELECT rels_1.objs[1] AS objs,
            array_cat(rels_1.schems, ARRAY[v.schem::text]) AS array_cat,
                CASE
                    WHEN v.f_tbl::text = rels_1.objs[rels_1.depth] THEN array_cat(rels_1.objs, ARRAY[v.tbl::text])
                    ELSE array_cat(rels_1.objs, ARRAY[v.f_tbl::text])
                END AS objs,
                CASE
                    WHEN v.f_tbl::text = rels_1.objs[rels_1.depth] THEN array_cat(rels_1.clmns, ARRAY[v.clmn])
                    ELSE array_cat(rels_1.clmns, ARRAY[v.clmn])
                END AS clmns,
                CASE
                    WHEN v.f_tbl::text = rels_1.objs[rels_1.depth] THEN array_cat(rels_1.dirxn, ARRAY['r'::text])
                    ELSE array_cat(rels_1.dirxn, ARRAY['l'::text])
                END AS dirxn,
                CASE
                    WHEN v.f_tbl::text = rels_1.objs[rels_1.depth] THEN array_cat(rels_1.path, ARRAY[ARRAY[v.clmn, v.tbl::text]])
                    ELSE array_cat(rels_1.path, ARRAY[ARRAY[v.clmn, v.f_tbl::text]])
                END AS path,
            rels_1.depth + 1
           FROM v_defr v
             JOIN rels rels_1 ON (v.f_tbl::text = rels_1.objs[rels_1.depth] OR v.tbl::text = rels_1.objs[rels_1.depth]) AND v.f_tbl <> 'users'::name AND v.tbl <> 'users'::name AND NOT ARRAY[ARRAY[ARRAY[v.tbl::text], ARRAY[v.clmn], ARRAY[v.f_tbl::text]]] <@ rels_1.path AND rels_1.depth < 7
        )
 SELECT rels.obj,
    rels.objs,
    rels.clmns,
    rels.schems,
    rels.dirxn,
    rels.path,
    rels.depth
   FROM rels
WITH DATA;

ALTER TABLE public.vm_rrels
  OWNER TO dynamain;
GRANT ALL ON TABLE public.vm_rrels TO dynamain;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.vm_rrels TO admin;
