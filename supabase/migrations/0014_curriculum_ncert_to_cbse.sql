-- NCERT publishes the CBSE textbooks — it is not a curriculum. Rewrites every
-- stored "NCERT" curriculum (any case/spacing, e.g. 'ncert', ' N CERT ') to 'CBSE'.
-- Idempotent: a second run matches nothing. Tables/columns missing in an
-- environment are skipped. Where a CBSE twin already exists under a unique key
-- (cache/dedupe tables, teacher_student), the NCERT row is the duplicate and is dropped.

do $$
declare
  spec   record;
  ctids  tid[];
  c      tid;
  is_ncert constant text := $q$upper(regexp_replace(%1$s, '\s', '', 'g')) = 'NCERT'$q$;
begin
  -- 1. Plain text columns: every public.<table>.curriculum, plus the columns that
  --    hold a curriculum under another name.
  for spec in
    select col.table_name as tbl, col.column_name as col, null::text as extra
    from information_schema.columns col
    join information_schema.tables t
      on t.table_schema = col.table_schema and t.table_name = col.table_name and t.table_type = 'BASE TABLE'
    where col.table_schema = 'public' and col.column_name = 'curriculum'
      and col.data_type in ('text', 'character varying')
    union all
    select x.tbl, x.col, x.extra
    from (values
      ('resource_files',   'scope',   null),
      ('resource_folders', 'scope',   null),
      ('teacher_student',  'subject', null),
      ('branding_logos',   'name',    $x$kind = 'curriculum'$x$)
    ) as x(tbl, col, extra)
    where exists (select 1 from information_schema.columns ic
                  where ic.table_schema = 'public' and ic.table_name = x.tbl and ic.column_name = x.col
                    and ic.data_type in ('text', 'character varying'))
  loop
    execute format('select array_agg(ctid) from public.%I where ' || format(is_ncert, quote_ident(spec.col)) || '%s',
                   spec.tbl, coalesce(' and ' || spec.extra, ''))
      into ctids;
    continue when ctids is null;
    foreach c in array ctids loop
      begin
        execute format('update public.%I set %I = ''CBSE'' where ctid = $1', spec.tbl, spec.col) using c;
      exception when unique_violation then
        execute format('delete from public.%I where ctid = $1', spec.tbl) using c;
      end;
    end loop;
  end loop;

  -- 2. JSON scalars: <table>.<jsonb column> #> path.
  for spec in
    select * from (values
      ('user_preferences',       'data',              '{curriculum}'),
      ('teacher_learning_paths', 'content',           '{metadata,curriculum}'),
      ('teacher_learning_paths', 'published_content', '{metadata,curriculum}'),
      ('teacher_curricula',      'extracted_structure', '{metadata,curriculum}'),
      ('teacher_curricula',      'extracted_structure', '{uploadConfig,curriculum}')
    ) as x(tbl, col, path)
    where exists (select 1 from information_schema.columns ic
                  where ic.table_schema = 'public' and ic.table_name = x.tbl and ic.column_name = x.col
                    and ic.data_type = 'jsonb')
  loop
    execute format(
      'update public.%1$I set %2$I = jsonb_set(%2$I, %3$L::text[], ''"CBSE"'') where '
        || format(is_ncert, format('(%I #>> %L::text[])', spec.col, spec.path)),
      spec.tbl, spec.col, spec.path);
  end loop;

  -- 3. JSON arrays of objects carrying their own curriculum: user_preferences.data.teaches[] / children[].
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'user_preferences' and column_name = 'data' and data_type = 'jsonb') then
    for spec in select unnest(array['teaches', 'children']) as key loop
      execute format($u$
        update public.user_preferences up
        set data = jsonb_set(up.data, array[%1$L], (
          select jsonb_agg(case when jsonb_typeof(e) = 'object' and %2$s
                                then jsonb_set(e, '{curriculum}', '"CBSE"') else e end order by i)
          from jsonb_array_elements(up.data -> %1$L) with ordinality as a(e, i)))
        where jsonb_typeof(up.data -> %1$L) = 'array'
          and exists (select 1 from jsonb_array_elements(up.data -> %1$L) as a(e) where %2$s)
      $u$, spec.key, format(is_ncert, '(e ->> ''curriculum'')'));
    end loop;
  end if;
end $$;
