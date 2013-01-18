CREATE SCHEMA plv8x;
REVOKE ALL ON SCHEMA plv8x FROM public;

COMMENT ON SCHEMA plv8x IS 'Out-of-table for loading plv8 modules';

CREATE TABLE plv8x.code (
    name text,
    code text,
    load_seq int,
    updated timestamp
);

