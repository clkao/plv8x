export function define-schema(name, comment, drop, cascade)
  dodrop = if drop => """
    ELSE EXECUTE 'DROP SCHEMA #name #{if cascade => 'CASCADE' else ''};
         CREATE SCHEMA #name';""" else ""

  """
DO $$
BEGIN

    IF NOT EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = '#name'
      )
    THEN
      EXECUTE 'CREATE SCHEMA #name';
    #dodrop
    END IF;

END

$$;

COMMENT ON SCHEMA #name IS '#comment';
  """

export function plv8x-sql(drop=false, cascade=false)
  define-schema(\plv8x 'Out-of-table for loading plv8 modules', drop, cascade) + """

CREATE TABLE IF NOT EXISTS plv8x.code (
    name text,
    code text,
    load_seq int,
    updated timestamp
);
  """

