DO $$
BEGIN

    IF NOT EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = 'plv8x'
      )
    THEN
      EXECUTE 'CREATE SCHEMA plv8x';
    END IF;

END

$$;

COMMENT ON SCHEMA plv8x IS 'Out-of-table for loading plv8 modules';

CREATE TABLE IF NOT EXISTS plv8x.code (
    name text,
    code text,
    load_seq int,
    updated timestamp
);

