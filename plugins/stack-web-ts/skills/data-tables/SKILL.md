---
name: data-tables
description: >
  How tables of data are built on the web-ts stack: one shared DataTable on TanStack Table v9, column defs and
  their meta, faceted filters, sorting, pagination, URL state through search params, and server-driven tables.
  Use it whenever you add a table, add or reorder a column, wire a filter, change what a table sorts or paginates
  by, or review the shared data-table component.
---

# Data tables

There is **one** table component, `src/components/data-table/`, and every table of data in the app goes through
it. The styled `<table>` primitive underneath (`components/ui/table`) is rendered directly only for a grid that is
not a dataset.

The rule that shapes everything: **the column def is the single source of truth.** Header text, sortability,
alignment, responsive hiding, the cell renderer and whether the column becomes a filter all live in one object. A
route never writes `<th>` or `<td>`.

## The pieces

| File | Role |
|---|---|
| `features.ts` | the shared `tableFeatures({…})` set, the `column.meta` and `table.meta` types, `createDataTableColumns` |
| `use-data-table.ts` | the hook: wires state to the URL **or** to component state, with the same signature |
| `data-table.tsx` | container, header row, cells, row link, empty state, pagination |
| `data-table-toolbar.tsx` | debounced search, faceted filters, reset, column visibility |
| `data-table-faceted-filter.tsx` | the multi-select popover with counts |
| `data-table-column-header.tsx` | the sortable header button |
| `data-table-pagination.tsx` | wraps the shared pagination, which card grids also use |
| `facet-filter.ts` | the project's own filter function for facets (see Traps) |

## The shape of a table

```tsx
const column = createDataTableColumns<Member>();

function buildColumns(onRemove: (id: string) => void) {
	return [
		column.accessor("name", {
			header: "Name",
			meta: { label: "Name" },
			cell: ({ row }) => <Link to="/members/$id" params={{ id: row.original.id }}>{row.original.name}</Link>,
		}),
		column.accessor("role", {
			header: "Role",
			filterFn: "facet",
			meta: { label: "Role", facet: { options: ROLE_OPTIONS, icon: ShieldIcon } },
			cell: ({ row }) => <Badge>{ROLE_LABELS[row.original.role]}</Badge>,
		}),
		column.display({
			id: "actions",
			header: "Actions",
			enableHiding: false,
			meta: { label: "Actions", align: "right" },
			cell: ({ row }) => <RowActions onRemove={() => onRemove(row.original.id)} />,
		}),
	];
}

const columns = useMemo(() => buildColumns(setRemoveId), []);

const table = useDataTable({
	data: members,
	columns,
	getRowId: row => row.id,
	searchFn: (m, q) => m.name.toLowerCase().includes(q) || m.email.toLowerCase().includes(q),
	urlState: { values: search, onChange: patch => navigate({ search: prev => ({ ...prev, ...patch }) }) },
});

<DataTable table={table} toolbar={<DataTableToolbar table={table} />} empty={<EmptyState … />} />
```

### `column.meta`

| Field | Effect |
|---|---|
| `label` | the name in the column-visibility menu and the filter's title |
| `align` | `left` (default), `center` or `right`, for header **and** cells |
| `hideBelow` | `sm`, `md`, `lg`, `xl`: hides header and cells together, so they can never drift apart |
| `headerClassName`, `cellClassName` | escape hatches for widths |
| `facet.options` | turns the column into a multi-select filter in the toolbar |
| `facet.icon` | the glyph the filter chip leads with |

`hideBelow` maps to literal class strings in `data-table.tsx`. A new breakpoint means a new literal there:
Tailwind's scanner cannot see an interpolated class name.

### Filters

The toolbar can show one button per facet, or a single filter icon with a removable chip per active facet, each
with an operator (is one of, is not one of). Both drive the same column filter state, so a column def does not
change between them.

A filter the table cannot own (a date range, a value that maps to a *set* of statuses) keeps its own state in the
URL and passes its control through the toolbar, so it still looks like part of the table. List its search params
in the hook's reset keys, or Reset leaves them behind.

### `DataTable` props

`toolbar`, `empty`, `rowLink`, `onRowClick`, `density`, `bordered` (pass `false` inside a card),
`showPagination`.

`rowLink` takes a bare `<Link>` with an `aria-label`; the trailing arrow cell and its column are added for you.
Return `null` for a row with nowhere to go, and its cell stays empty while the column keeps its shape.
`onRowClick` makes the whole row a pointer target, skipping clicks on links and buttons inside it. A row cannot
take focus, so pair it with a `rowLink` to the same place.

## State: URL or local

`urlState` is opt-in and both modes share a signature, so switching is one prop.

```ts
// route
validateSearch: z.object({ ...dataTableSearchFields, role: dataTableFilterField }),

// component
const navigate = useNavigate({ from: Route.fullPath });
const search = Route.useSearch();
```

`dataTableSearchFields` gives `q`, `page`, `sort`, `dir`. **Add one `dataTableFilterField` per faceted column,
named exactly after the column id**: the hook reads `search[columnId]` as a comma-separated list. Column
visibility, widths and row selection stay local on purpose; they are noise in a URL.

What the hook enforces, so routes do not reimplement it:

- A default value is written as `undefined`, which **removes** the param and keeps the URL clean.
- Any filter or sort change resets `page`.
- `enableSortingRemoval: false`: a header cycles asc, desc, asc. There is no third "unsorted" state, because the
  URL could not tell it from "never sorted".
- Reset goes through one `table.options.meta.resetFilters()`. The per-slice reset APIs fire two `navigate` calls
  in one tick with URL state, and the second reads stale params and drops the first.

Use local state when several tables share a page and would collide on `page` and `sort`.

## Recipes

**Search across several fields.** The default global filter matches each column's accessor only. Pass
`searchFn: (row, query) => …` to replace it with a row-level predicate; `query` arrives lowercased and trimmed.

**A facet over a list** (a row that belongs to several groups): the accessor returns the `string[]`, keep
`filterFn: "facet"`, and add `getUniqueValues: row => row.groups` so the popover counts each value, not each
combination.

**Cells do not wrap.** Every cell is `whitespace-nowrap`; a table wider than its card scrolls sideways. A second
line under a name is `max-w-* truncate`, never `line-clamp-1`, or the column grows to the full text. A column meant
to wrap says so in `cellClassName`.

**No pagination** (a short, complete list): `showPagination={false}` and `pageSize: Math.max(rows.length, 1)`. A
page size of 0 breaks the row model.

**Several tables on one page.** Hooks cannot run in a `.map()`: extract a child component that calls the hook once
and render it per group. Build the column defs once in the parent.

**A server-driven table**: pass `manual: { pageCount, rowCount }`, which turns on manual pagination, sorting and
filtering, so the table renders `data` as given. Mark every column `enableSorting: false` unless the endpoint
really accepts that sort: a header that sorts nothing is worse than no header control.

## Traps

**`filterFn: "facet"` on every faceted column**, with the project's own facet function registered in
`features.ts`: a list of values means "the row's value is one of these", and a leading `!` on the first token
negates the selection. The built-ins do not fit:

- `arrIncludesSome` returns false when the *row* value is not an array, so on a scalar column it matches nothing.
- `arrIncludes` matches substrings, so filtering `ADMIN` also returns `SUPERADMIN`.
- Leaving `filterFn` off makes TanStack pick `includesString`, which never matches an array of selected values.

**Facet values must be strings.** A boolean column filtered from the URL receives `["true"]` and never matches.
Project it: `column.accessor(r => (r.isPublic ? "public" : "private"), { id: "visibility", … })`.

**Column defs need a stable identity.** Module scope when they close over nothing, `useMemo` otherwise. A fresh
array on every render rebuilds every column and row model. `useState` setters are stable, so
`useMemo(() => buildColumns(setId), [])` is honest.

**Display columns can never sort**, so `enableSorting: false` on a `column.display` is noise. Do set
`enableHiding: false` on an actions column.

**`tsc` proves nothing about filter or sort behaviour.** The traps above compile and fail silently. Check them by
reading the built-in's source under `node_modules/@tanstack/table-core`, or by rendering the hook in a jsdom test
and asserting on `table.getRowModel().rows`.

## TanStack Table v9, not v8

Version 9 is a redesign, and most snippets you will find online are v8:

| v8 | v9 |
|---|---|
| `getCoreRowModel()` and friends passed to `useReactTable` | features declared once in `tableFeatures({…})` with row-model factories |
| `useReactTable` | `useTable` |
| `table.getState()` | `table.state` |
| `sortingFn` | `sortFn` |
| `ColumnMeta` by global declaration merging | the `columnMeta` and `tableMeta` slots on the features object |

Only the features listed in `features.ts` exist on the instance. Adding one (grouping, pinning) means registering
the feature *and* its row-model factory there, so every table keeps the same capabilities. When in doubt, read the
installed `.d.ts` files rather than the docs site.

## Before calling it done

```bash
pnpm exec tsc --noEmit
pnpm test
pnpm build
```

Then, because none of that exercises a filter: **click each faceted filter in the browser** and confirm it narrows
the table instead of emptying it, and check that the page survives a refresh and the back button, which is the
point of URL state. If the route has a loading skeleton, update it to mirror the toolbar.
