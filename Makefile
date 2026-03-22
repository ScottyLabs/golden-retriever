.PHONY: fmt fmt-json fmt-terraform fmt-whitespace lint visualize

# Fix all formatting issues in one shot.
fmt: fmt-whitespace fmt-json fmt-terraform

# Trim trailing whitespace and ensure final newlines on all tracked text files.
fmt-whitespace:
	@echo "==> Fixing trailing whitespace and final newlines..."
	@python3 -c "\
	import subprocess, pathlib; \
	files = subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'], text=True).splitlines(); \
	[fix(p) for f in files if (p:=pathlib.Path(f)).is_file() and not f.startswith(('.terraform/','.git/')) and p.suffix not in ('.png','.jpg','.gif','.woff','.woff2','.ttf','.ico') for fix in [lambda p: p.write_text('\n'.join(line.rstrip() for line in p.read_text().splitlines()) + '\n')]];\
	"
	@echo "    Done."

# Pretty-print all JSON data files with consistent 2-space indentation.
fmt-json:
	@echo "==> Formatting JSON files..."
	@for f in contributors/*.json repos/*.json figma-projects/*.json google-files/*.json teams/*.json schemas/*.json; do \
		[ -f "$$f" ] || continue; \
		python3 -c "import json,pathlib;p=pathlib.Path('$$f');p.write_text(json.dumps(json.loads(p.read_text()),indent=2)+'\n')"; \
	done
	@echo "    Done."

# Run terraform fmt on all .tf files.
fmt-terraform:
	@echo "==> Formatting Terraform files..."
	@terraform fmt -recursive .
	@echo "    Done."

# Run all checks (same as CI).
lint: lint-editorconfig lint-json lint-terraform lint-refs

lint-editorconfig:
	@echo "==> Checking EditorConfig compliance..."
	@editorconfig-checker --exclude LICENSE --exclude '.terraform'

lint-json:
	@echo "==> Validating JSON schemas..."
	@for f in contributors/*.json repos/*.json figma-projects/*.json google-files/*.json teams/*.json; do \
		[ -f "$$f" ] || continue; \
		python3 -m json.tool "$$f" > /dev/null; \
	done
	@echo "    All JSON files are syntactically valid."

lint-terraform:
	@echo "==> Validating Terraform..."
	@terraform fmt -check -recursive -diff .
	@terraform validate

lint-refs:
	@echo "==> Checking cross-references..."
	@python3 -c "\
	import json, sys, os; \
	ok = True; \
	teams = {f.removesuffix('.json'): json.load(open(os.path.join('teams', f))) for f in os.listdir('teams') if f.endswith('.json')}; \
	repos = {f.removesuffix('.json') for f in os.listdir('repos') if f.endswith('.json')}; \
	figma = {f.removesuffix('.json') for f in os.listdir('figma-projects') if f.endswith('.json')}; \
	gfiles = {f.removesuffix('.json') for f in os.listdir('google-files') if f.endswith('.json')}; \
	contribs = {f.removesuffix('.json') for f in os.listdir('contributors') if f.endswith('.json')}; \
	[\
		(print(f'ERROR: teams/{s}.json: slug {t[\"slug\"]!r} != filename {s!r}') or setattr(sys.modules[__name__], '_ok', False)) \
		if t.get('slug') != s else None \
		for s, t in teams.items() \
	]; \
	[\
		(print(f'ERROR: teams/{s}.json: contributor {c!r} not found') or setattr(sys.modules[__name__], '_ok', False)) \
		for s, t in teams.items() for c in t.get('contributors', []) if c not in contribs \
	]; \
	[\
		(print(f'ERROR: teams/{s}.json: maintainer {m!r} not in contributors') or setattr(sys.modules[__name__], '_ok', False)) \
		for s, t in teams.items() for m in t.get('maintainers', []) if m not in set(t.get('contributors', [])) \
	]; \
	[\
		(print(f'ERROR: teams/{s}.json: repo {r!r} not found') or setattr(sys.modules[__name__], '_ok', False)) \
		for s, t in teams.items() for r in t.get('repos', []) if r not in repos \
	]; \
	[\
		(print(f'ERROR: teams/{s}.json: figma_project {fp!r} not found') or setattr(sys.modules[__name__], '_ok', False)) \
		for s, t in teams.items() for fp in t.get('figma_projects', []) if fp not in figma \
	]; \
	[\
		(print(f'ERROR: teams/{s}.json: google_file {gf!r} not found') or setattr(sys.modules[__name__], '_ok', False)) \
		for s, t in teams.items() for gf in t.get('google_files', []) if gf not in gfiles \
	]; \
	print('    All cross-references valid.') if ok else sys.exit(1); \
	"

# Build the force-directed governance visualizer to dist/index.html.
visualize:
	@echo "==> Building visualizer..."
	@cd visualizer && npm install --silent && npm run build
	@echo "    Output: dist/index.html"
