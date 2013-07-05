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

DO $$ BEGIN CREATE TABLE plv8x.code (
    name text PRIMARY KEY,
    code text,
    load_seq int,
    updated timestamp
); EXCEPTION WHEN OTHERS THEN END; $$;
  """

export function operators-sql()
  '''
DROP OPERATOR IF EXISTS |> (NONE, text); CREATE OPERATOR |> (
    RIGHTARG = text,
    PROCEDURE = plv8x.json_eval
);
DROP OPERATOR IF EXISTS |> (plv8x.json, text); CREATE OPERATOR |> (
    LEFTARG = plv8x.json,
    RIGHTARG = text,
    COMMUTATOR = <|,
    PROCEDURE = plv8x.json_eval
);
DROP OPERATOR IF EXISTS <| (text, plv8x.json); CREATE OPERATOR <| (
    LEFTARG = text,
    RIGHTARG = plv8x.json,
    COMMUTATOR = |>,
    PROCEDURE = plv8x.json_eval
);

DROP OPERATOR IF EXISTS ~> (NONE, text); CREATE OPERATOR ~> (
    RIGHTARG = text,
    PROCEDURE = plv8x.json_eval_ls
);
DROP OPERATOR IF EXISTS ~> (plv8x.json, text); CREATE OPERATOR ~> (
    LEFTARG = plv8x.json,
    RIGHTARG = text,
    COMMUTATOR = <~,
    PROCEDURE = plv8x.json_eval_ls
);
DROP OPERATOR IF EXISTS <~ (text, plv8x.json); CREATE OPERATOR <~ (
    LEFTARG = text,
    RIGHTARG = plv8x.json,
    COMMUTATOR = ~>,
    PROCEDURE = plv8x.json_eval_ls
);
  '''
