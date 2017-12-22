-- creates a shortened view of v_defrels
--  simply works towards creating a short relationship view of foreign table constraints
-- View: public.v_defr

-- DROP VIEW public.v_defr;

CREATE OR REPLACE VIEW public.v_defr AS 
 SELECT v_defrels.table_schema AS schem,
    v_defrels.table_name AS tbl,
    array_to_string(v_defrels.columns, ''::text) AS clmn,
    v_defrels.foreign_table_schema AS f_schem,
    v_defrels.foreign_table_name AS f_tbl,
    array_to_string(v_defrels.foreign_columns, ''::text) AS f_clmn
   FROM v_defrels;

ALTER TABLE public.v_defr
  OWNER TO dynamain;
GRANT ALL ON TABLE public.v_defr TO dynamain;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.v_defr TO admin;
