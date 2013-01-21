export function _mk_func (
  name, param-obj, ret, body, lang = \plv8, skip-compile
)
  params = []
  args = for pname, type of param-obj
    params.push "#pname #type"
    if type is \pgrest_json
      "JSON.parse(#pname)"
    else pname

  if lang is \plls and not skip-compile
    lang = \plv8
    [{ compiled }] = plv8.execute do
      'SELECT jsapply($1, $2) AS compiled'
      'LiveScript.compile'
      JSON.stringify [body, { +bare }]
    compiled -= /;$/

  compiled ||= body
  body = "JSON.stringify((eval(#compiled))(#args));";

  return """

SET client_min_messages TO WARNING;
DO \$PGREST_EOF\$ BEGIN

DROP FUNCTION IF EXISTS #{name} (#params);
DROP FUNCTION IF EXISTS #{name} (#{
  for p in params
    if p is /pgrest_json/ then \json else p
});

CREATE FUNCTION #name (#params) RETURNS #ret AS \$PGREST_#name\$
return #body
\$PGREST_#name\$ LANGUAGE #lang IMMUTABLE STRICT;

EXCEPTION WHEN OTHERS THEN END; \$PGREST_EOF\$;

  """
