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
