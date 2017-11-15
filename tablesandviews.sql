with tblviews as (with thetables as (SELECT DISTINCT 'table' as type, info.table_schema AS SCHEMA, info.table_name AS TABLE_NAME,
	info.column_name AS name, info.domain_name, info.ordinal_position AS POSITION,
	info.is_nullable::boolean AS NULLABLE, CASE
	WHEN info.data_type = 'USER-DEFINED' THEN info.udt_name
	ELSE info.data_type
	END AS col_type, info.is_updatable::boolean AS updatable, info.character_maximum_length AS max_len,
	info.numeric_precision AS PRECISION, info.column_default AS default_value,
	array_to_string(enum_info.vals, ',') AS enum, null as vtable_schema, null as vtable_name
      FROM
        (WITH columns AS
           (SELECT DISTINCT table_schema, TABLE_NAME AS TABLE_NAME, COLUMN_NAME, udt_name,
						 domain_name, ordinal_position, is_nullable::boolean, data_type, is_updatable::boolean,
						 character_maximum_length, numeric_precision, column_default
							FROM INFORMATION_SCHEMA.COLUMNS
							WHERE table_schema <> 'pg_catalog'
								AND table_schema <> 'information_schema' )
				 SELECT table_schema, TABLE_NAME,
              COLUMN_NAME, domain_name, ordinal_position, is_nullable, data_type, is_updatable,
              character_maximum_length, numeric_precision, column_default, udt_name /*-- FROM information_schema.columns*/
         FROM columns
         WHERE table_schema NOT IN ('pg_catalog', 'information_schema') ) AS info
				LEFT OUTER JOIN
        (SELECT n.nspname AS s, t.typname AS n, array_agg(e.enumlabel
                                                          ORDER BY e.enumsortorder) AS vals
         FROM pg_type t
         JOIN pg_enum e ON t.oid = e.enumtypid
         JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
         GROUP BY s, n) AS enum_info ON (info.udt_name = enum_info.n)
      )

      select * from thetables
      union

      	select distinct
				'view' as type,
				nv.nspname::information_schema.sql_identifier as table_schema,
				v.relname::information_schema.sql_identifier as table_name,
				a.attname::information_schema.sql_identifier as name,
				null as domain_name,
				a.attnum as position,
				null::boolean as nullable,
				pg_catalog.format_type(a.atttypid, a.atttypmod) as col_type,
				false as updatable,
				null::integer as max_len,
				null::integer as precision,
				null as default_value,
				null as enum,
				nt.nspname::information_schema.sql_identifier as vtable_schema,
				t.relname::information_schema.sql_identifier as vtable_name
		from pg_namespace nv
		join pg_class v on nv.oid = v.relnamespace
		join pg_depend dv on v.oid = dv.refobjid
		join pg_depend dt on dv.objid = dt.objid
		join pg_class t on dt.refobjid = t.oid
		join pg_namespace nt on t.relnamespace = nt.oid
		join pg_attribute a on t.oid = a.attrelid and dt.refobjsubid = a.attnum

		where
				nv.nspname not in ('information_schema', 'pg_catalog')
				and v.relkind = 'v'::"char"
				and dv.refclassid = 'pg_class'::regclass::oid
				and dv.classid = 'pg_rewrite'::regclass::oid
				and dv.deptype = 'i'::"char"
				and dv.refobjid <> dt.refobjid
				and dt.classid = 'pg_rewrite'::regclass::oid
				and dt.refclassid = 'pg_class'::regclass::oid
				and (t.relkind = any (array['r'::"char", 'v'::"char", 'f'::"char"]))


)
select type, schema, table_name, json_agg((name, domain_name, position, nullable, col_type, updatable, max_len, precision, precision, default_value, enum, vtable_schema, vtable_name)) as fieldData
  from tblviews group by type, schema, table_name
				
