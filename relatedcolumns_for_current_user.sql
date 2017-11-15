
 with perms as (
 SELECT pg_user.usename AS username,
    pg_namespace.nspname AS schema,
    pg_class.relname AS relation,
        CASE pg_class.relkind
            WHEN 'r'::"char" THEN 'TABLE'::text
            WHEN 'v'::"char" THEN 'VIEW'::text
            ELSE NULL::text
        END AS relation_type,
    privs.priv
   FROM pg_class
     JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace,
    pg_user,
    ( VALUES ('SELECT'::text,1), ('INSERT'::text,2), ('UPDATE'::text,3), ('DELETE'::text,4)) privs(priv, privorder)
  WHERE (pg_class.relkind = ANY (ARRAY['r'::"char", 'v'::"char"])) AND has_table_privilege(pg_user.usesysid, pg_class.oid, privs.priv) AND NOT (pg_namespace.nspname ~ '^pg_'::text OR pg_namespace.nspname = 'information_schema'::name)
  ORDER BY pg_namespace.nspname, pg_user.usename, pg_class.relname, privs.privorder
	), relatedcolumns as (
	    SELECT ns1.nspname AS table_schema,
	           tab.relname AS table_name,
	           column_info.cols AS columns,
	           ns2.nspname AS foreign_table_schema,
	           other.relname AS foreign_table_name,
	           column_info.refs AS foreign_columns
	    FROM pg_constraint,
	       LATERAL (SELECT array_agg(cols.attname) AS cols,
	                       array_agg(cols.attnum)  AS nums,
	                       array_agg(refs.attname) AS refs
	                  FROM ( SELECT unnest(conkey) AS col, unnest(confkey) AS ref) k,
	                       LATERAL (SELECT * FROM pg_attribute
	                                 WHERE attrelid = conrelid AND attnum = col)
	                            AS cols,
	                       LATERAL (SELECT * FROM pg_attribute
	                                 WHERE attrelid = confrelid AND attnum = ref)
	                            AS refs)
	            AS column_info,
	       LATERAL (SELECT * FROM pg_namespace WHERE pg_namespace.oid = connamespace) AS ns1,
	       LATERAL (SELECT * FROM pg_class WHERE pg_class.oid = conrelid) AS tab,
	       LATERAL (SELECT * FROM pg_class WHERE pg_class.oid = confrelid) AS other,
	       LATERAL (SELECT * FROM pg_namespace WHERE pg_namespace.oid = other.relnamespace) AS ns2
	    WHERE confrelid != 0
	    ORDER BY (conrelid, column_info.nums)
)
select relatedcolumns.* from relatedcolumns
join perms on perms.relation = relatedcolumns.table_name and perms.schema = relatedcolumns.table_schema
 and perms.username = current_user; 
