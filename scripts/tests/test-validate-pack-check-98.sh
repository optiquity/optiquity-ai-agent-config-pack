#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-98.sh — synthetic tests for Check 98
# (shipped client-editable trinity content must be marker-backed).
#
# The graft engine (scripts/lib/marker-preserve.sh) keeps ONLY what sits inside a
# project-owned marker pair. So a shipped fill-in placeholder that sits OUTSIDE a
# pair is a value the next `--update` silently reverts, and a shipped instruction
# telling the client to DELETE pack content is an instruction the graft undoes.
# Check 98 FAILs on both shapes over the git-TRACKED client trinity.
#
# declare-verify-backing: the guard is asserted to BITE the ABSENCE-of-backing
# instance (T3 — a pair stripped from around a placeholder that STAYS), not
# merely the target-exists instance; and to SPARE the correct shipped wording
# (T5 negated instruction, T7 legitimate deletion-verb prose, T8 fenced example).
# Every BITE case has a paired SPARE built from the same bytes, so no assertion
# can pass for a reason unrelated to the rule.
#
# This test is NOT fixture-dependent (it `git init`s throwaway repos in /tmp
# REPO_ROOTs and monkeypatches the module's REPO_ROOT — the Check 63/92/93
# technique). It lives under scripts/tests/ and auto-wires into CI via the disk
# glob. Per "Test infra is self-provisioned": the REAL project-template trinity
# is NEVER mutated — T3's mutant is built from an in-memory copy.
#
# The pre-remediation fixture (T12) is SYNTHETIC, deliberately: a test that read
# a specific historical SHA would break on a shallow CI clone. The reproduction
# against the real historical bytes is a one-off measurement recorded in the
# BD-294 C3 implementation report, not a standing assertion.
#
# Coverage:
#   Group 0: Module import + Check 98 registration + __all__ export + DYNAMIC
#            count invariant + NO allowlist symbol exists + the registered
#            callable's TARGET (the project-template tree, verified by calling
#            it, not by trusting the label)
#   Group 1: Real-state-at-HEAD PASS (0 findings on the shipped trinity)
#   Group 2: Synthetic PASS/BITE/SPARE against /tmp git repos:
#            - T1  PASS : compliant trinity (placeholders inside pairs)  -> 0
#            - T2  BITE : placeholder OUTSIDE every pair                 -> 1
#            - T3  BITE : MUTANT, pair stripped + placeholder KEPT       -> 1
#            - T4  BITE : affirmative "delete the entire section"        -> 1
#            - T5  SPARE: negated "suppress it - do not delete it"       -> 0
#            - T6  BITE : instruction hard-WRAPPED across two lines      -> 1
#            - T7  SPARE: legitimate deletion-verb prose (dead code,
#                         add/remove/prune, file deletion, deletes ...)  -> 0
#            - T8  SPARE: placeholder inside a fenced code block         -> 0
#            - T9  BITE : "does not apply, delete the entire section"
#                         (the negation set is TIGHT: `does not` is not a
#                         member, so this still BITEs)                   -> 1
#            - T10 BITE : UNCLOSED pair around a placeholder (an orphan
#                         BEGIN backs nothing)                           -> 1
#            - T11 BITE : zero tracked trinity files, git available
#                         (never vacuous)                                -> 1
#            - T12 BITE : pre-remediation-SHAPED trinity, EXACT counts,
#                         incl. a two-match line that must count ONCE
#                         (pins the one-finding-per-line-per-leg rule) -> many
#            - T13 SKIP : REPO_ROOT at a NON-git dir -> SKIP-lenient     -> 0
#            - T14 SKIP : trinity_root OUTSIDE REPO_ROOT -> SKIP-lenient -> 0
#            - T15 BITE : trinity on disk but UNTRACKED -> not a
#                         candidate (enumeration is git-TRACKED, never a
#                         filesystem walk)                               -> 1
#            - T16 SKIP : `git` BINARY absent (FileNotFoundError)
#                         -> SKIP-lenient, + a control that the same
#                         bodies BITE once the binary is back            -> 0
#            - T17 BITE : deletion object is a markdown CODE SPAN        -> 1
#            - T18 SPARE: ALL-CAPS markdown LINK is not a placeholder,
#                         and a placeholder on the same line still is    -> 0
#            - T19 BITE : every object-noun admitted beyond the original
#                         measured set fires, one assertion per member,
#                         + the singular `file` stays EXCLUDED (it
#                         measured 3 false positives on the shipped
#                         trinity)                                       -> 1 each
#            - T20 BITE : "strictly inside" is strict at BOTH ends - a
#                         placeholder trailing the BEGIN or the END
#                         marker on the same line is on the fence, not
#                         the interior; + an interior control           -> 1/1/0
#            - T21 BITE/SPARE: EVERY matcher-vocabulary member is
#                         individually load-bearing - the three tuples
#                         are pinned to LITERAL expected sets, and each
#                         of the 45 members carries its own behavioural
#                         assertion (verbs/nouns FIRE, negation tokens
#                         SPARE). Drop any ONE and this turns red    -> 45
#            - T22 BITE : a deletion instruction INSIDE a well-formed
#                         project-owned pair is still reported - leg 2
#                         skips only FENCED lines, never backed ones
#                         (the pair parses clean, so Check 91 does not
#                         fire on it either)                            -> 1
#            - T23 SPARE/BITE: the fence rule both ways - an instruction
#                         typeset inside a fence is spared, but leg 2's
#                         two-line WINDOW still reads a lang-tagged
#                         fence opener as the object half and attributes
#                         it to the prose line above                  -> 0/1
#            - T24 BITE : the banner ARITHMETIC at sizes other than
#                         T12's 30 - 21 findings/19 lines -> "(+1 more)",
#                         and exactly 20 -> no suffix at all (the cap
#                         boundary is `<= 20`)                         -> 1/1
#            - T25 BITE/SPARE: the numeric bounds and the window SHAPE
#                         are load-bearing in BOTH directions - a
#                         widened negation window silently spares a real
#                         instruction, a narrowed one flags correct
#                         wording, a widened gap glues a verb to an
#                         unrelated noun, a three-line window joins two
#                         paragraphs                                 -> 1/0/0/0
#            - T26 SPARE/BITE: the matcher's STRUCTURAL bounds -
#                         `_c98_alt` longest-first + re.escape-d, the
#                         gap class excluding `.`, the `\b`s that keep
#                         BOTH vocabularies EXACT (`removed`,
#                         `shortcut`, `stripped`, `blocklist`,
#                         `intersection` are not members), the
#                         3-character placeholder-token minimum both
#                         ways, and the outside-REPO_ROOT branch
#                         returning WITHOUT spawning git      -> 0 x6, 1/0, 0
#            - T27 BITE : the CORPUS edges every other case misses,
#                         because they all write the SAME body to all
#                         three files - exactly ONE defective file, a
#                         tracked file MISSING from the work tree, ALL
#                         of them missing (nothing scanned is never
#                         nothing wrong), and undecodable bytes  -> 1/1/1/1
#   Group 3: End-to-end validate-pack.py --only-check 98 on HEAD (rc 0)
#
# Usage: bash scripts/tests/test-validate-pack-check-98.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
export REPO_ROOT VALIDATE

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
    return 0
}

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/vp-check98.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT
export SCRATCH

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + Check 98 registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 98 registration ===\n"

python3 - > "$SCRATCH/import.out" 2>&1 <<'PY'
import os, sys
REPO_ROOT = os.environ['REPO_ROOT']; VALIDATE = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT + '/scripts')
sys.path.insert(0, REPO_ROOT + '/scripts/lib')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# The star-import must EXPORT the new check: a function missing from the
# module's __all__ would NameError at the registry site.
from validate_checks import trinity_markers as tm
if 'check_trinity_editable_marker_backed' not in tm.__all__:
    print('FAIL_NOT_IN_ALL ' + repr(tm.__all__)); sys.exit(1)
for name in ('check_trinity_editable_marker_backed', '_C98_PLACEHOLDER_RE',
             '_C98_INSTRUCTION_RE', '_C98_NEGATION_RE', '_C98_DELETION_VERBS',
             '_C98_PACK_CONTENT_NOUNS', '_C98_NEGATION_TOKENS',
             '_c98_scan_text', '_c98_candidate_files'):
    if not hasattr(mod, name) and not hasattr(tm, name):
        print('FAIL_MISSING ' + name); sys.exit(1)

nums = [t[0] for t in mod._build_check_registry()]
if 98 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
# Registered ONCE (project-template only), never double-registered at pack-root.
if nums.count(98) != 1:
    print('FAIL_REGISTERED_TWICE ' + str(nums.count(98))); sys.exit(1)
# BD-289's reserved slots must stay free.
if 95 in nums or 96 in nums:
    print('FAIL_STOLE_RESERVED_SLOT'); sys.exit(1)
# DYNAMIC count invariant (Check 59's): the registry add + the count bump
# landed together. No hardcoded literal here.
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
# NO allowlist: the measured legitimate set is empty, and an allowlist that
# does not exist cannot grow. Adding one is itself a failure here.
allow = [a for a in dir(tm) if 'ALLOWLIST' in a.upper()]
if allow:
    print('FAIL_ALLOWLIST_EXISTS ' + repr(allow)); sys.exit(1)
# The registry RECORDS a mapping (number -> label -> callable). Verify the
# LOAD-BEARING end of it, not merely that the number is present: a lambda aimed
# at the wrong tree keeps the number, the label, the count and the exit code,
# and checks the wrong files. Call the registered callable with the check
# function swapped for a recorder and pin the arguments.
entry = [t for t in mod._build_check_registry() if t[0] == 98][0]
if entry[1] != 'check_trinity_editable_marker_backed[project-template]':
    print('FAIL_REGISTRY_LABEL ' + repr(entry[1])); sys.exit(1)
called = []
real_fn = mod.check_trinity_editable_marker_backed
try:
    mod.check_trinity_editable_marker_backed = (
        lambda *a, **k: called.append((a, k)))
    entry[2]()
finally:
    mod.check_trinity_editable_marker_backed = real_fn
want_call = [((mod.REPO_ROOT / 'project-template', 'project-template'), {})]
if called != want_call:
    print('FAIL_REGISTRY_TARGET %r (want %r)' % (called, want_call)); sys.exit(1)
print('OK')
PY
if grep -q "^OK$" "$SCRATCH/import.out"; then
    t_pass "Check 98 exported via __all__, registered ONCE against the project-template tree (target verified, not just the number), 95/96 still free, DYNAMIC count invariant holds, NO allowlist symbol"
else
    t_fail "Check 98 registration / export / count / allowlist invariant failed" \
        "$(cat "$SCRATCH/import.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

python3 - > "$SCRATCH/real.out" 2>&1 <<'PY'
import os, sys, io, contextlib, pathlib
REPO_ROOT = os.environ['REPO_ROOT']
sys.path.insert(0, REPO_ROOT + '/scripts/lib')
from validate_checks import trinity_markers as tm
from validate_checks import core
core.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    tm.check_trinity_editable_marker_backed(
        pathlib.Path(REPO_ROOT) / 'project-template', 'project-template')
print('FAILURES', len(core.failures))
print(buf.getvalue())
# Anti-vacuity: the shipped trinity must actually CONTAIN placeholders (all of
# them marker-backed) and legitimate deletion-verb prose. A clean run over files
# with neither would prove nothing.
names = ('CLAUDE.md', 'AGENTS.md', 'GEMINI.md')
ph = 0
for n in names:
    text = (pathlib.Path(REPO_ROOT) / 'project-template' / n).read_text()
    ph += len(tm._C98_PLACEHOLDER_RE.findall(text))
print('SHIPPED_PLACEHOLDERS', ph)
PY
REAL_PH="$(sed -n 's/^SHIPPED_PLACEHOLDERS //p' "$SCRATCH/real.out")"
if grep -q "^FAILURES 0$" "$SCRATCH/real.out" \
   && grep -q "every fill-in placeholder sits inside a project-owned marker pair" "$SCRATCH/real.out" \
   && [[ "${REAL_PH:-0}" -ge 9 ]]; then
    t_pass "real trinity at HEAD: 0 findings, and it really does ship placeholders (${REAL_PH}) — all marker-backed"
else
    t_fail "real trinity at HEAD: Check 98 reported findings, an unexpected message, or no placeholders to back" \
        "$(cat "$SCRATCH/real.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic PASS / BITE / SPARE against /tmp git repos
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic PASS/BITE/SPARE (monkeypatched REPO_ROOT) ===\n"

python3 - > "$SCRATCH/synth.out" 2>&1 <<'PY'
import contextlib, io, os, pathlib, subprocess, sys, tempfile
REPO_ROOT = os.environ['REPO_ROOT']; SCRATCH = os.environ['SCRATCH']
sys.path.insert(0, REPO_ROOT + '/scripts/lib')
from validate_checks import trinity_markers as tm
from validate_checks import core

NAMES = ('CLAUDE.md', 'AGENTS.md', 'GEMINI.md')
failures = []

BEGIN = '<!-- BEGIN project-owned -->'
END = '<!-- END project-owned -->'

def body(section_extra='', preamble='', fenced='', pair=True, ph='[PLATFORM_DEFAULTS - fill in]'):
    """A minimal COMPLIANT trinity body; knobs mutate exactly one property."""
    inner = '\n'.join([BEGIN, ph, END]) if pair else ph
    return '\n'.join([
        '# NAME.md', '', preamble, '## Platform and stack defaults', '',
        inner, '', '## Rules', '', section_extra, fenced, '',
    ]) + '\n'

def make_root(tag, bodies, extra=None, stage=None):
    """Build a throwaway git repo. `stage` = pathspecs to index (default: all).

    Passing an explicit `stage` leaves everything else UNTRACKED on disk, which
    is how T15 separates "exists on disk" from "is in the index".
    """
    root = pathlib.Path(tempfile.mkdtemp(prefix='c98-%s-' % tag, dir=SCRATCH))
    (root / 'project-template').mkdir(parents=True)
    for name, text in bodies.items():
        (root / 'project-template' / name).write_text(text)
    for rel, text in (extra or {}).items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
    subprocess.run(['git', 'init', '-q'], cwd=root, check=True)
    subprocess.run(['git', 'config', 'user.email', 't@t.t'], cwd=root, check=True)
    subprocess.run(['git', 'config', 'user.name', 't'], cwd=root, check=True)
    subprocess.run(['git', 'add'] + (list(stage) if stage else ['-A']),
                   cwd=root, check=True)
    return root

def run(root, trinity_root=None):
    saved_root, saved = tm.REPO_ROOT, list(core.failures)
    core.failures.clear()
    tm.REPO_ROOT = pathlib.Path(root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            tm.check_trinity_editable_marker_backed(
                trinity_root or (pathlib.Path(root) / 'project-template'),
                'project-template')
        return (len(core.failures), buf.getvalue())
    finally:
        tm.REPO_ROOT = saved_root
        core.failures.clear()
        core.failures.extend(saved)

def uniform(text):
    return dict((n, text) for n in NAMES)

def expect(tag, n, cap, want_n, want_sub=None, want_absent=None):
    if n != want_n:
        failures.append('%s expected %d failure(s), got %d: %s' % (tag, want_n, n, cap[:400]))
        return
    if want_sub and want_sub not in cap:
        failures.append('%s expected %r in output: %s' % (tag, want_sub, cap[:400]))
    if want_absent and want_absent in cap:
        failures.append('%s did NOT expect %r in output: %s' % (tag, want_absent, cap[:400]))

# T1 PASS - compliant baseline. Every later BITE is this body with ONE change.
GOOD = body()
n, cap = run(make_root('t1', uniform(GOOD)))
expect('T1 (compliant)', n, cap, 0, want_sub='3 trinity file(s)')

# T2 BITE - the SAME placeholder with the pair removed at authoring time.
n, cap = run(make_root('t2', uniform(body(pair=False))))
expect('T2 (placeholder outside every pair)', n, cap, 1,
       want_sub='unbacked-placeholder')

# T3 BITE - the ABSENCE-of-backing MUTANT: start from the compliant bytes and
# delete ONLY the two marker lines; the placeholder is asserted to SURVIVE.
mutant = '\n'.join(l for l in GOOD.splitlines()
                   if l.strip() not in (BEGIN, END)) + '\n'
if '[PLATFORM_DEFAULTS' not in mutant:
    failures.append('T3 setup: the placeholder did not survive the mutation - vacuous mutant')
if mutant.count(BEGIN) != GOOD.count(BEGIN) - 1 or mutant.count(END) != GOOD.count(END) - 1:
    failures.append('T3 setup: marker counts did not drop by exactly 1 - wrong mutant shape')
n, cap = run(make_root('t3', uniform(mutant)))
expect('T3 (MUTANT: pair stripped, placeholder kept)', n, cap, 1,
       want_sub='unbacked-placeholder')

# T4 BITE - affirmative deletion instruction.
n, cap = run(make_root('t4', uniform(body(
    section_extra='If it is irrelevant, delete the entire section.'))))
expect('T4 (affirmative delete-the-entire-section)', n, cap, 1,
       want_sub='unhonourable-instruction')

# T5 SPARE - the CORRECT wording, same sentence negated.
n, cap = run(make_root('t5', uniform(body(
    section_extra='If it is irrelevant, suppress it - do not delete the section.'))))
expect('T5 (negated: do not delete the section)', n, cap, 0)

# T6 BITE - the instruction hard-WRAPPED across a line break. A line-based
# matcher misses this; the two-line window must catch it.
n, cap = run(make_root('t6', uniform(body(
    section_extra='If your project does not use it, remove the\nentire section from this file.'))))
expect('T6 (instruction wrapped across a hard line break)', n, cap, 1,
       want_sub='unhonourable-instruction')

# T7 SPARE - legitimate deletion-verb prose that ships today and must not fire.
LEGIT = '\n'.join([
    '- Prefer deleting dead code over preserving speculative abstractions.',
    'Update this line whenever skills are added or removed mid-project.',
    'any `git rm`, `rm -rf`, file deletion, overwrite, or any',
    '`git worktree` (add/remove/prune) - on a file with uncommitted',
    'deletes or destructively overwrites nothing outside that dir',
])
n, cap = run(make_root('t7', uniform(body(section_extra=LEGIT))))
expect('T7 (legitimate deletion-verb prose)', n, cap, 0)

# T8 SPARE - a placeholder inside a fenced code block is an EXAMPLE, not a slot.
n, cap = run(make_root('t8', uniform(body(
    fenced='```\n[PLATFORM_TESTING - example only]\n```'))))
expect('T8 (placeholder inside a ``` fence)', n, cap, 0)

# T9 BITE - the negation set is TIGHT: `does not` is not a negation token, so
# the classic shipped sentence still BITEs. Paired with T5, this proves the
# negation carve-out is narrow rather than a blanket escape hatch.
n, cap = run(make_root('t9', uniform(body(
    section_extra='If it does not apply, delete the entire section.'))))
expect('T9 (does-not-apply is not a negation)', n, cap, 1,
       want_sub='unhonourable-instruction')

# T10 BITE - an UNCLOSED pair backs nothing.
orphan = '\n'.join(['# NAME.md', '', '## Platform and stack defaults', '',
                    BEGIN, '[PLATFORM_DEFAULTS - fill in]', '', '## Rules', '']) + '\n'
n, cap = run(make_root('t10', uniform(orphan)))
expect('T10 (unclosed BEGIN backs nothing)', n, cap, 1,
       want_sub='unbacked-placeholder')

# T11 BITE - zero tracked trinity files while git IS available: never vacuous.
root = make_root('t11', {}, extra={'project-template/README.md': 'x\n'})
n, cap = run(root)
expect('T11 (zero tracked trinity files -> never vacuous)', n, cap, 1,
       want_sub='refuses to pass vacuously')

# T12 BITE - a pre-remediation-SHAPED trinity: placeholders outside pairs in the
# preamble AND the delete-instructions, i.e. the shape the guard exists to stop.
PRE = '\n'.join([
    '# NAME.md', '',
    '<!--', 'HOW TO USE THIS TEMPLATE', '',
    'Fill in [PROJECT_NAME], [PLATFORM_TARGETS], and [TRANSPORT] during setup.',
    'Fill in or remove the optional sections based on your project type.',
    'Remove this comment block after filling in the placeholders.', '-->', '',
    '---', '*Fill in placeholders and remove this block.*', '---', '',
    '**[PROJECT_NAME]** targets [PLATFORM_TARGETS].', '',
    '## Platform and stack defaults', '',
    '[PLATFORM_DEFAULTS - fill in per project type]', '',
    '<!-- OPTIONAL: keep this section if it applies; delete the entire section if not -->',
    '## gRPC rules', '',
    '[GRPC_RULES - fill in from grpc-patterns skill, or delete section]', '',
    # ONE physical line carrying TWO leg-2 matches ("Delete the section" and
    # "remove the block"). Leg 2 `break`s after the first, so this line must
    # contribute exactly 1 - which is what pins the one-finding-per-line-per-leg
    # rule below. Drop the `break` and the exact count becomes 7, not 6.
    'Delete the section above and remove the block below when unused.', '',
]) + '\n'
if len(tm._C98_INSTRUCTION_RE.findall(
        'Delete the section above and remove the block below when unused.')) != 2:
    failures.append('T12 setup: the dedup line no longer carries TWO leg-2 '
                    'matches - the `break` assertion below would be vacuous')
n, cap = run(make_root('t12', uniform(PRE)))
# The per-kind tally in the FAIL message is what a human reads off CI, so it is
# asserted verbatim: 3 identical files x (4 placeholder + 6 instruction) lines.
WANT_COUNTS = "{'unbacked-placeholder': 12, 'unhonourable-instruction': 18}"
if WANT_COUNTS not in cap:
    failures.append('T12 message tally: expected %s in the failure text: %s'
                    % (WANT_COUNTS, cap[:400]))
# The LEADING total, pinned as a literal. `findings` is one entry per
# (file, line, LEG), so the 30 findings here sit on 27 DISTINCT lines - line 24
# of each file trips both legs. The banner must not label one number as the
# other, and neither number may be a hard-coded literal in the source: both are
# asserted here, in one substring.
WANT_TOTAL = '27 shipped trinity line(s) (30 finding(s))'
if WANT_TOTAL not in cap:
    failures.append('T12 leading total: expected %r in the failure text: %s'
                    % (WANT_TOTAL, cap[:400]))
# 30 findings > the 20-finding detail cap, so BOTH halves of the cap are live
# here and both are pinned: the QUOTED entry count (the `[kind]` tag appears in
# bracketed form only inside a detail entry - the trailing explanation uses the
# backticked form) and the overflow ARITHMETIC. The suffix alone would not
# discriminate: `more` is computed from the literal 20, not from the slice.
n_detail = (cap.count('[unbacked-placeholder]')
            + cap.count('[unhonourable-instruction]'))
if n_detail != 20:
    failures.append('T12 detail cap: expected exactly 20 quoted findings, got '
                    '%d' % n_detail)
if '(+10 more)' not in cap:
    failures.append('T12 detail cap: expected 30 findings capped at 20 with a '
                    '"(+10 more)" suffix: %s' % cap[-200:])
if n != 1:
    failures.append('T12 expected 1 failure, got %d' % n)
elif 'unbacked-placeholder' not in cap or 'unhonourable-instruction' not in cap:
    failures.append('T12 expected BOTH legs to fire: %s' % cap[:400])
else:
    per = tm._c98_scan_text(PRE)
    kinds = {}
    for _, k, _ in per:
        kinds[k] = kinds.get(k, 0) + 1
    # EXACT, not a floor: the fixture carries 4 placeholder lines (the three
    # setup tokens on one line, the identity line, PLATFORM_DEFAULTS, GRPC_RULES)
    # and 6 instruction lines ("remove the optional sections", "Remove this
    # comment block", "remove this block", "delete the entire section", "or
    # delete section", and the two-match dedup line counted ONCE). An exact
    # count catches an over-report as well as an under-report - it is what
    # kills both the attribution-off (over) and noun-narrow (under) mutants,
    # and now the break-off (dedup) mutant too.
    if kinds != {'unbacked-placeholder': 4, 'unhonourable-instruction': 6}:
        failures.append('T12 mis-reported the pre-remediation shape: %r '
                        '(want 4 placeholder + 6 instruction lines)' % kinds)
    # Leg 1 counts LINES but its evidence is a TOKEN list, so a narrowing that
    # drops one token from a MULTI-token line leaves the line count intact and
    # slips past the counts above. Pin the token set on the three-token setup
    # line - the only line in the fixture that can discriminate.
    setup_line = [ev for _, k, ev in per
                  if k == 'unbacked-placeholder' and 'TRANSPORT' in ev]
    want_setup = ['[PLATFORM_TARGETS…], [PROJECT_NAME…], [TRANSPORT…]']
    if setup_line != want_setup:
        failures.append('T12 leg-1 evidence: the three-token setup line must '
                        'list ALL THREE tokens, got %r (want %r)'
                        % (setup_line, want_setup))

# T13 SKIP - REPO_ROOT at a NON-git directory -> git ls-files unavailable.
nongit = pathlib.Path(tempfile.mkdtemp(prefix='c98-t13-', dir=SCRATCH))
(nongit / 'project-template').mkdir(parents=True)
for nm in NAMES:
    (nongit / 'project-template' / nm).write_text(body(pair=False))
n, cap = run(nongit)
expect('T13 (non-git dir -> SKIP-lenient)', n, cap, 0,
       want_sub='git ls-files unavailable')

# T14 SKIP - trinity_root OUTSIDE REPO_ROOT -> SKIP-lenient.
outside = pathlib.Path(tempfile.mkdtemp(prefix='c98-t14-', dir=SCRATCH))
(outside / 'project-template').mkdir(parents=True)
for nm in NAMES:
    (outside / 'project-template' / nm).write_text(body(pair=False))
n, cap = run(make_root('t14', uniform(GOOD)),
             trinity_root=outside / 'project-template')
expect('T14 (trinity_root outside REPO_ROOT -> SKIP-lenient)', n, cap, 0,
       want_sub='git ls-files unavailable')

# T15 BITE - the enumeration is git-TRACKED, never a filesystem walk. Three
# COMPLIANT trinity bodies sit ON DISK but only a non-trinity file is staged, so
# the tracked trinity set is EMPTY and the never-vacuous rule must fire. This is
# the ONLY case that separates `git ls-files` from `git ls-files --others
# --cached` (or any rglob/os.walk): under a walk the three on-disk files are
# candidates, they are compliant, and the check would report 0.
t15 = make_root('t15', uniform(GOOD),
                extra={'project-template/README.md': 'x\n'},
                stage=['project-template/README.md'])
tracked15 = subprocess.run(['git', 'ls-files'], cwd=t15,
                           capture_output=True, text=True).stdout.split()
ondisk15 = sorted(p.name for p in (t15 / 'project-template').iterdir())
if tracked15 != ['project-template/README.md']:
    failures.append('T15 setup: tracked set is %r, want only the README - the '
                    'assertion would not discriminate' % tracked15)
if not all(nm in ondisk15 for nm in NAMES):
    failures.append('T15 setup: the trinity is not on disk (%r) - vacuous '
                    'fixture, a walk would find nothing either' % ondisk15)
n, cap = run(t15)
expect('T15 (untracked trinity is NOT a candidate: tracked, never a walk)',
       n, cap, 1, want_sub='refuses to pass vacuously')

# T16 SKIP - the `git` BINARY absent -> FileNotFoundError -> SKIP-lenient. The
# bodies are NON-compliant on purpose: a lenient skip must be a genuine skip,
# not a lucky pass on clean content. Shim `tm.subprocess` only (the module's own
# reference); this script's `subprocess` name is untouched, so make_root above
# still ran against the real binary.
class _NoGitBinary(object):
    @staticmethod
    def run(*a, **k):
        raise FileNotFoundError(2, 'No such file or directory', 'git')

t16 = make_root('t16', uniform(body(pair=False)))
saved_sp = tm.subprocess
try:
    tm.subprocess = _NoGitBinary
    n, cap = run(t16)
finally:
    tm.subprocess = saved_sp
if tm.subprocess is not saved_sp:
    failures.append('T16 teardown: tm.subprocess was not restored')
expect('T16 (git binary absent -> SKIP-lenient)', n, cap, 0,
       want_sub='git ls-files unavailable')
# Control: the SAME non-compliant bodies BITE once the binary is back, so T16's
# 0 came from the lenient branch and not from a fixture that never fired.
n, cap = run(t16)
expect('T16 control (same bodies BITE with git available)', n, cap, 1,
       want_sub='unbacked-placeholder')

# T17 BITE - the deletion object is a markdown CODE SPAN. The pack backticks
# section names everywhere, so this is the most likely re-introduction wording;
# a gap class that excluded the backtick waved it through.
n, cap = run(make_root('t17', uniform(body(
    section_extra='If it does not apply, delete the `## iOS 26` section.'))))
expect('T17 (backticked object between verb and noun)', n, cap, 1,
       want_sub='unhonourable-instruction')

# T18 SPARE - leg 1 must not flag an inline markdown LINK whose text is an
# ALL-CAPS token, and must STILL flag a real placeholder on the SAME line. One
# fixture, both directions: a matcher that stopped flagging placeholders to
# spare links would fail the second half.
LINKY = '\n'.join([
    'See [CLAUDE.md](./CLAUDE.md) and [MERGE-STRATEGY](./docs/m.md).',
])
n, cap = run(make_root('t18', uniform(body(section_extra=LINKY))))
expect('T18 (ALL-CAPS markdown link is not a placeholder)', n, cap, 0)
mixed = tm._c98_scan_text('# N\n\n## H\n\n[PROJECT_NAME] - see [CLAUDE.md](./CLAUDE.md).\n')
mixed_ph = [ev for _, k, ev in mixed if k == 'unbacked-placeholder']
if mixed_ph != ['[PROJECT_NAME…]']:
    failures.append('T18b: a line carrying BOTH a placeholder and a link must '
                    'report ONLY the placeholder, got %r' % mixed_ph)

# T19 BITE - every object-noun admitted beyond the original measured set must
# actually FIRE. A vocabulary member with no assertion behind it is a guard that
# cannot fail, so each is pinned individually: drop any ONE member and this
# turns red rather than silently narrowing recall.
NOUN_CASES = {
    'text': 'Remove the following text if your project is Python-only.',
    'files': 'Delete these files if the project has no gRPC.',
    'lines': 'Delete these lines if the project has no gRPC.',
    'paragraph': 'Strip the paragraph below when it does not apply.',
    'content': 'Remove the content above if your project is Swift-only.',
}
for _noun, _sentence in sorted(NOUN_CASES.items()):
    if _noun not in tm._C98_PACK_CONTENT_NOUNS:
        failures.append('T19 %r: dropped from _C98_PACK_CONTENT_NOUNS' % _noun)
        continue
    _hits = [e for _, k, e in tm._c98_scan_text(_sentence + '\n')
             if k == 'unhonourable-instruction']
    if len(_hits) != 1:
        failures.append('T19 %r: %r produced %r, want exactly 1 leg-2 hit'
                        % (_noun, _sentence, _hits))
# The SINGULAR `file` is deliberately EXCLUDED: it measured 3 false positives on
# the shipped trinity (one per file, on the `git worktree (add/remove/prune) -
# on a file with uncommitted ...` destructive-ops line). Assert the exclusion so
# a future widening has to re-measure both corpora rather than re-admit it by
# assumption.
if 'file' in tm._C98_PACK_CONTENT_NOUNS:
    failures.append("T19: 'file' was re-admitted to _C98_PACK_CONTENT_NOUNS - "
                    'it measured 3 FALSE POSITIVES on the shipped trinity; '
                    're-measure the shipped AND pre-remediation corpora first')

# T20 BITE - "NOT strictly inside a marker region" is strict at BOTH ends. A
# placeholder that TRAILS the BEGIN or the END marker on the SAME physical line
# is on the FENCE, not in the interior, so the graft does not keep it. Both
# shapes parse cleanly into a region (no `_scan_markers` error), so an
# off-by-one in the backed-range would silently spare a real defect at either
# end. Paired with a control that the interior IS spared.
T20_ON_BEGIN = '\n'.join([
    '# NAME.md', '', '## Platform and stack defaults', '',
    BEGIN + ' [PLATFORM_X - fill]', '', END, '']) + '\n'
T20_ON_END = '\n'.join([
    '# NAME.md', '', '## Platform and stack defaults', '',
    BEGIN, '', END + ' [PLATFORM_X - fill]', '']) + '\n'
T20_INTERIOR = '\n'.join([
    '# NAME.md', '', '## Platform and stack defaults', '',
    BEGIN, '[PLATFORM_X - fill]', END, '']) + '\n'
for _i, (_tag, _text, _want) in enumerate((
        ('on the BEGIN line', T20_ON_BEGIN, 1),
        ('on the END line', T20_ON_END, 1),
        ('in the interior (control)', T20_INTERIOR, 0))):
    # Anti-vacuity: all three must parse to exactly ONE well-formed region, or
    # the cases would be distinguishing marker parsing, not the strictness rule.
    _scan = tm._scan_markers(_text)
    if len(_scan['regions']) != 1:
        failures.append('T20 setup (%s): want exactly 1 region, got %r'
                        % (_tag, _scan['regions']))
    n, cap = run(make_root('t20-%d' % _i, uniform(_text)))
    expect('T20 (placeholder %s)' % _tag, n, cap, _want,
           want_sub='unbacked-placeholder' if _want else None)

# T21 BITE/SPARE - EVERY matcher-vocabulary member is individually load-bearing.
# T19 pins the five nouns admitted after the original measurement; this pins all
# forty-five. Two halves, both required:
#   (a) MEMBERSHIP - each tuple is compared against a LITERAL expected set.
#       Iterating the LIVE tuple would go vacuous exactly when a member is
#       dropped, which is the trap. Equality (not containment) also catches a
#       silent WIDENING, which is what `ci-guard-measure-then-bound` demands: a
#       new member has to re-measure both corpora and land here deliberately.
#   (b) BEHAVIOUR - one assertion per member, proving the member actually FIRES
#       (verbs, nouns) or actually SPARES (negation tokens). Membership alone
#       would pass a member that is present but unreachable - a mis-escaped
#       alternation, or a `\b` that cannot bite an inflected form.
# Dropping a verb or a noun silently NARROWS recall (the guard stops catching a
# shape and CI stays green); dropping a negation token silently WIDENS the
# carve-out and changes which correct shipped wording gets flagged. Both are the
# "guard that cannot fail" class, so both directions are pinned.
T21_VERBS = ('delete', 'deletes', 'deleting', 'remove', 'removes', 'removing',
             'strip', 'strips', 'stripping', 'erase', 'erases', 'erasing',
             'drop', 'drops', 'dropping', 'cut', 'excise', 'excises',
             'excising')
T21_NOUNS = ('section', 'sections', 'subsection', 'subsections',
             'block', 'blocks', 'heading', 'headings', 'placeholder',
             'placeholders', 'text', 'files', 'lines', 'paragraph', 'content')
T21_NEGS = ('do not', "don't", 'never', 'must not', 'should not', "shouldn't",
            'cannot', "can't", 'rather than', 'instead of', 'without')
for _tup, _want_tup, _live_tup in (
        ('_C98_DELETION_VERBS', T21_VERBS, tm._C98_DELETION_VERBS),
        ('_C98_PACK_CONTENT_NOUNS', T21_NOUNS, tm._C98_PACK_CONTENT_NOUNS),
        ('_C98_NEGATION_TOKENS', T21_NEGS, tm._C98_NEGATION_TOKENS)):
    if tuple(_live_tup) != _want_tup:
        failures.append('T21 membership: %s is %r, want %r - a vocabulary '
                        'change must re-measure BOTH corpora (shipped trinity '
                        'stays 0, pre-remediation stays >0) and land here'
                        % (_tup, tuple(_live_tup), _want_tup))


def leg2_hits(text):
    """Leg-2 evidence for a one-line fixture (no git root needed)."""
    return [e for _, k, e in tm._c98_scan_text(text + '\n')
            if k == 'unhonourable-instruction']


for _verb in T21_VERBS:
    _vs = '%s the section below' % _verb
    if len(leg2_hits(_vs)) != 1:
        failures.append('T21 verb %r: %r produced %r, want exactly 1 leg-2 hit '
                        '- the member is in the tuple but does not FIRE'
                        % (_verb, _vs, leg2_hits(_vs)))
for _obj in T21_NOUNS:
    _os = 'Delete the %s below' % _obj
    if len(leg2_hits(_os)) != 1:
        failures.append('T21 noun %r: %r produced %r, want exactly 1 leg-2 hit '
                        '- the member is in the tuple but does not FIRE'
                        % (_obj, _os, leg2_hits(_os)))
for _neg in T21_NEGS:
    _gs = 'x %s delete the section below' % _neg
    if leg2_hits(_gs):
        failures.append('T21 negation %r: %r produced %r, want 0 leg-2 hits - '
                        'a negated instruction is the CORRECT shipped wording'
                        % (_neg, _gs, leg2_hits(_gs)))

# T22 BITE - leg 2 does NOT skip marker-backed lines. A seed pair's contents are
# shipped pack bytes too, so a delete-instruction inside one is just as
# un-obeyable. The pair here parses CLEANLY - one region, no `_scan_markers`
# error - so Check 91 does not fire on it either: leg 2 is the only thing
# standing between this shape and a silent pass. Every other instruction case
# (T4/T6/T9/T17) puts the sentence in `section_extra`, which `body()` emits
# OUTSIDE the pair, so none of them reaches the backed interior.
T22_IN_PAIR = '\n'.join([
    '# NAME.md', '', '## Platform and stack defaults', '',
    BEGIN, 'If it is irrelevant, delete the entire section.', END, '']) + '\n'
_scan22 = tm._scan_markers(T22_IN_PAIR)
_backed22 = set()
for _r22 in _scan22['regions']:
    _backed22.update(range(_r22['begin_ln'] + 1, _r22['end_ln']))
# Anti-vacuity, three ways: exactly ONE region, NO marker error (so the finding
# cannot be a mis-parse), and the instruction line really IS in the backed
# interior - without that last check the case would just be re-running T4.
if len(_scan22['regions']) != 1 or _scan22['errors']:
    failures.append('T22 setup: want exactly 1 well-formed region and no '
                    'marker error, got regions=%r errors=%r'
                    % (_scan22['regions'], _scan22['errors']))
if 6 not in _backed22:
    failures.append('T22 setup: the instruction on line 6 is NOT marker-backed '
                    '(backed=%r) - the case would not discriminate'
                    % sorted(_backed22))
_hits22 = [(_ln, _k) for _ln, _k, _ in tm._c98_scan_text(T22_IN_PAIR)]
if _hits22 != [(6, 'unhonourable-instruction')]:
    failures.append('T22: a deletion instruction INSIDE a project-owned pair '
                    'must still be reported (leg 2 skips only FENCED lines, '
                    'never backed ones), got %r' % _hits22)
n, cap = run(make_root('t22', uniform(T22_IN_PAIR)))
expect('T22 (deletion instruction inside a well-formed pair)', n, cap, 1,
       want_sub='unhonourable-instruction', want_absent='[unbacked-placeholder]')

# T23 SPARE/BITE - the fence rule in BOTH directions, exactly as the leg-2
# docstring states it. (a) A fenced line is not an ATTRIBUTION site: an
# instruction typeset entirely inside a fence is an illustrative example and is
# spared. (b) Leg 2's WINDOW is the deliberate exception - the i+1 half is taken
# unconditionally, so a hard-wrapped instruction whose object half lands on a
# fence opener carrying a language tag is still attributed to the NON-fenced
# prose line above it. `text` is both a common markdown language tag and an
# object noun, so (b) is reachable; it is fail-loud (a red CI on a clean tree)
# rather than a silent miss, and the shipped tree carries 0 occurrences.
FENCE = '`' * 3
T23_INSIDE = '\n'.join([
    '# NAME.md', '', '## Rules', '',
    FENCE, 'If it is irrelevant, delete the entire section.', FENCE, '']) + '\n'
T23_ONTO_OPENER = '\n'.join([
    '# NAME.md', '', '## Rules', '',
    'If your project is Python-only, remove the',
    FENCE + 'text', 'swift snippet', FENCE, '']) + '\n'
# Anti-vacuity for (a): the very same sentence MUST fire when it is not fenced,
# or the SPARE would pass for a reason unrelated to the fence rule.
if len(leg2_hits('If it is irrelevant, delete the entire section.')) != 1:
    failures.append('T23 control: the sentence does not fire when UNFENCED - '
                    'the fenced SPARE below would be vacuous')
# Anti-vacuity for (b): pin the attributed LINE and the evidence. A window built
# from the next NON-fenced line would report nothing; attributing to the fence
# opener would report line 6.
_hits23 = [(_ln, _ev) for _ln, _k, _ev in tm._c98_scan_text(T23_ONTO_OPENER)
           if _k == 'unhonourable-instruction']
if _hits23 != [(5, 'remove the ' + FENCE + 'text')]:
    failures.append('T23b: the wrapped instruction must be attributed to the '
                    'non-fenced prose line 5, got %r' % _hits23)
for _tag23, _text23, _want23 in (
        ('instruction typeset inside a fence', T23_INSIDE, 0),
        ('object half wrapped onto a lang-tagged fence opener',
         T23_ONTO_OPENER, 1)):
    if not tm._scan_markers(_text23)['fenced']:
        failures.append('T23 setup (%s): the fixture has no fenced lines'
                        % _tag23)
    n, cap = run(make_root('t23-%d' % _want23, uniform(_text23)))
    expect('T23 (%s)' % _tag23, n, cap, _want23,
           want_sub='unhonourable-instruction' if _want23 else None)

# T24 BITE - the banner's ARITHMETIC, at two sizes other than T12's. T12 has
# exactly 30 findings, so a hard-coded `(+10 more)` satisfies it and a hard-coded
# total satisfies it: one fixture size cannot discriminate a computation from a
# literal. These two do.
#   (a) 21 findings over 19 distinct lines -> `(+1 more)`.
#   (b) EXACTLY 20 -> the cap boundary is `<= 20`, so NO suffix at all; an
#       off-by-one there would emit "(+0 more)".
T24_SMALL = body(section_extra='If it is irrelevant, delete the entire section.')
_pre_n = len(tm._c98_scan_text(PRE))
_small_n = len(tm._c98_scan_text(T24_SMALL))
_good_n = len(tm._c98_scan_text(GOOD))
if (_pre_n, _small_n, _good_n) != (10, 1, 0):
    failures.append('T24 setup: per-file findings are PRE=%d SMALL=%d GOOD=%d, '
                    'want 10/1/0 - the literal totals below would not '
                    'discriminate' % (_pre_n, _small_n, _good_n))
n, cap = run(make_root('t24a', {'CLAUDE.md': PRE, 'AGENTS.md': PRE,
                                'GEMINI.md': T24_SMALL}))
expect('T24a (21 findings / 19 lines -> overflow of exactly one)', n, cap, 1,
       want_sub='19 shipped trinity line(s) (21 finding(s))')
if '(+1 more)' not in cap:
    failures.append('T24a overflow: 21 findings capped at 20 must carry a '
                    '"(+1 more)" suffix computed from the ACTUAL total: %s'
                    % cap[-240:])
_detail_a = (cap.count('[unbacked-placeholder]')
             + cap.count('[unhonourable-instruction]'))
if _detail_a != 20:
    failures.append('T24a detail cap: expected exactly 20 quoted findings, got '
                    '%d' % _detail_a)
n, cap = run(make_root('t24b', {'CLAUDE.md': PRE, 'AGENTS.md': PRE,
                                'GEMINI.md': GOOD}))
expect('T24b (exactly 20 findings / 18 lines -> at the cap, no suffix)',
       n, cap, 1, want_sub='18 shipped trinity line(s) (20 finding(s))',
       want_absent=' more)')

# T25 BITE/SPARE - the two numeric bounds and the window SHAPE are load-bearing
# in BOTH directions. Tightening was already caught (T4 dies at gap 0, T12 at a
# narrow gap, T5 at a zero negation window); WIDENING was not, and each widening
# has a measured, realistic consequence:
#   (a) _C98_NEG_WINDOW=24 - the negation here sits 42 chars back, ACROSS a
#       sentence boundary, and belongs to a different clause. Any widening to
#       >= 42 silently SPARES a real instruction. "Do not edit this file by
#       hand" is ordinary pack prose, so the false negative is reachable.
#   (b) the SAME bound from below - the `Never` sits 15 chars back, so narrowing
#       to 8 wrongly FLAGS correct negated wording.
#   (c) _C98_GAP=40 - the verb and the noun here are 71 chars apart in one
#       clause. Widening glues them together, and removing a command-line FLAG
#       is not deleting a pack section.
#   (d) the window is TWO lines, not three: a blank line ends the markdown
#       paragraph, so prose either side of it is not one instruction.
T25_NEG_FAR = 'Do not edit this file by hand. If unused, delete the section.'
T25_NEG_NEAR = 'Never manually delete the section.'
T25_GAP_FAR = ('Remove the `--dry-run` flag once you have reviewed the plan, '
               'then re-run the sections you skipped.')
T25_THREE_LINE = ('If your project does not use it, remove the\n\n'
                  'entire section from this file.')
for _tag25, _text25, _want25, _why25 in (
        ('(a) negation 42 chars back, across a sentence boundary',
         T25_NEG_FAR, 1,
         'a widened negation window reaches a `Do not` from another clause'),
        ('(b) negation 15 chars back', T25_NEG_NEAR, 0,
         'a narrowed negation window cannot reach the `Never`'),
        ('(c) verb and noun 71 chars apart', T25_GAP_FAR, 0,
         'a widened gap glues a verb to an unrelated noun'),
        ('(d) instruction split across a BLANK line', T25_THREE_LINE, 0,
         'a three-line window would join two separate paragraphs')):
    _got25 = leg2_hits(_text25)
    if len(_got25) != _want25:
        failures.append('T25 %s: %r produced %r, want %d leg-2 hit(s) - %s'
                        % (_tag25, _text25, _got25, _want25, _why25))
# End-to-end through the real check, not just the scanner, for the BITE half.
n, cap = run(make_root('t25', uniform(body(section_extra=T25_NEG_FAR))))
expect('T25a (negation across a sentence boundary still BITEs)', n, cap, 1,
       want_sub='unhonourable-instruction')

# T26 SPARE/BITE - the matcher's STRUCTURAL bounds. Each is a clause the module
# states and, until here, nothing asserted; each case below is the counter-example
# produced by the mutant that survived without it.
#   (a) `_c98_alt` is LONGEST-FIRST and `re.escape`-d. The ordering is
#       behaviourally equivalent while both `\b`s stand (verified: identical
#       output over the shipped corpus), so it is pinned as a UNIT contract - a
#       helper contract asserted by nothing is the same defect one level down.
#       The escaping is NOT equivalent: a future member carrying a regex
#       metacharacter would silently become a wildcard.
#   (b) the gap class excludes `.`, which is what bounds a match to ONE clause.
#       Widened to `[^\n]`, a noun one sentence later is glued to the verb.
#   (c) BOTH alternations are `\b`-bounded at BOTH ends, which is what keeps the
#       vocabulary EXACT. `removed`, `shortcut` and `stripped` are not members,
#       and neither are `blocklist` or `intersection`; unbounded, the verb
#       alternation finds `remove`/`cut`/`strip` inside the first three and the
#       noun alternation finds `block`/`section` inside the last two - five
#       legitimate sentences flagged.
#   (d) a placeholder token is at least THREE characters (`[A-Z][A-Z_]{2,}`):
#       `[IDE]` is a fill-in slot, `[XY]` is too short to be one. Both
#       directions, because both bounds are silently movable otherwise.
#   (e) the outside-REPO_ROOT branch returns BEFORE spawning git. T14 pins the
#       SKIP but not the COST: delete the early return and the check still
#       skips - git just errors on an absolute pathspec - so only a
#       process-count assertion sees the difference
#       (`ci-check-runtime-compounding`).
if tm._c98_alt(('a', 'bbb', 'cc')) != 'bbb|cc|a':
    failures.append('T26a: _c98_alt must emit LONGEST-first, got %r'
                    % tm._c98_alt(('a', 'bbb', 'cc')))
if tm._c98_alt(('a.b',)) != 'a\\.b':
    failures.append('T26a: _c98_alt must re.escape its members, got %r'
                    % tm._c98_alt(('a.b',)))
for _tag26, _text26 in (
        ('(b) a period ends the clause',
         'Update the file and remove trailing whitespace. The section stays.'),
        ('(c) `removed` is not a vocabulary member',
         'Any line removed from the block below stays removed.'),
        ('(c) `cut` inside `shortcut`',
         'Use the shortcut lines below as a quick reference.'),
        ('(c) `strip` inside `stripped`',
         'A stripped heading is still a heading.'),
        ('(c) `block` inside `blocklist`',
         'Remove any stale entry from the blocklist.'),
        ('(c) `section` inside `intersection`',
         'Delete the row at the intersection of the two axes.')):
    if leg2_hits(_text26):
        failures.append('T26 %s: %r must NOT fire, got %r'
                        % (_tag26, _text26, leg2_hits(_text26)))
for _tok26, _want26 in (('[IDE]', ['[IDE…]']), ('[XY]', [])):
    _got26 = [_ev for _, _k, _ev in tm._c98_scan_text('# N\n\n## H\n\n%s\n'
                                                      % _tok26)
              if _k == 'unbacked-placeholder']
    if _got26 != _want26:
        failures.append('T26d %s: leg 1 reported %r, want %r - a placeholder '
                        'token is `[A-Z][A-Z_]{2,}`, THREE characters minimum'
                        % (_tok26, _got26, _want26))

_T26_GIT_CALLS = []


class _CountingGit(object):
    """Records every subprocess the module would spawn, and spawns none."""

    class _Result(object):
        returncode = 0
        stdout = ''
        stderr = ''

    @staticmethod
    def run(*a, **k):
        _T26_GIT_CALLS.append(list(a[0]) if a else None)
        return _CountingGit._Result()


t26e = make_root('t26e', uniform(GOOD))          # built BEFORE the shim
_saved_sp26 = tm.subprocess
try:
    tm.subprocess = _CountingGit
    n, cap = run(t26e, trinity_root=outside / 'project-template')
finally:
    tm.subprocess = _saved_sp26
if tm.subprocess is not _saved_sp26:
    failures.append('T26e teardown: tm.subprocess was not restored')
expect('T26e (outside REPO_ROOT: SKIP without spawning git)', n, cap, 0,
       want_sub='git ls-files unavailable')
if _T26_GIT_CALLS:
    failures.append('T26e: the outside-REPO_ROOT branch spawned git %d time(s) '
                    '(%r) - the early return exists so the check never pays for '
                    'a process to learn the root is out of tree'
                    % (len(_T26_GIT_CALLS), _T26_GIT_CALLS))

# T27 BITE - the CORPUS itself. Every synthetic case above writes the SAME body
# to all three files, so every one of them produces at least three findings and
# scans exactly three files. That leaves the corpus edges untested, and each edge
# is reachable on a real clone:
#   (a) exactly ONE file is defective (a hand-edit to CLAUDE.md alone) - a
#       single finding must still FAIL, and the message must name that file and
#       not the clean two.
#   (b) a tracked file MISSING from the work tree - `except OSError: continue`
#       skips it so the other two are still scanned and still reported.
#   (c) ALL tracked files missing - the read loop drops everything, so `findings`
#       is empty for a reason that is NOT "the trinity is clean". Nothing scanned
#       is never nothing wrong: this must FAIL, not report the all-clear.
#   (d) undecodable bytes - `errors="replace"` keeps the file in the corpus
#       instead of raising, so its placeholders are still found.
ONE_BAD = body(pair=False)
n, cap = run(make_root('t27a', {'CLAUDE.md': ONE_BAD, 'AGENTS.md': GOOD,
                                'GEMINI.md': GOOD}))
expect('T27a (only ONE of the three files is defective)', n, cap, 1,
       want_sub='CLAUDE.md:', want_absent='AGENTS.md:')
if '1 shipped trinity line(s) (1 finding(s))' not in cap:
    failures.append('T27a: a single finding must be reported as 1 line / 1 '
                    'finding: %s' % cap[:300])

t27b = make_root('t27b', uniform(ONE_BAD))
os.unlink(t27b / 'project-template' / 'CLAUDE.md')       # tracked, now absent
_tracked27 = subprocess.run(['git', 'ls-files'], cwd=t27b,
                            capture_output=True, text=True).stdout.split()
if len(_tracked27) != 3:
    failures.append('T27b setup: the index must still carry all three files, '
                    'got %r - the OSError branch would not be reached'
                    % _tracked27)
n, cap = run(t27b)
expect('T27b (one tracked file missing from the work tree: the rest still scan)',
       n, cap, 1, want_sub='2 shipped trinity line(s) (2 finding(s))',
       want_absent='CLAUDE.md:')

t27c = make_root('t27c', uniform(ONE_BAD))
for _nm27 in NAMES:
    os.unlink(t27c / 'project-template' / _nm27)
n, cap = run(t27c)
expect('T27c (ALL tracked files missing -> never vacuous)', n, cap, 1,
       want_sub='NONE could be read', want_absent='every fill-in placeholder')

t27d = make_root('t27d', uniform(GOOD))
(t27d / 'project-template' / 'CLAUDE.md').write_bytes(
    b'# N\n\n## H\n\n[PLATFORM_DEFAULTS - fill in] \xff\xfe\n')
n, cap = run(t27d)
expect('T27d (undecodable bytes stay in the corpus, not raise)', n, cap, 1,
       want_sub='CLAUDE.md:5')

# R16 vocabulary-drift gate: the shipped OPTIONAL wording and this guard must
# not drift apart. 0 matches in the real shipped files, >0 in the shape above.
shipped_hits = 0
for nm in NAMES:
    text = (pathlib.Path(REPO_ROOT) / 'project-template' / nm).read_text()
    shipped_hits += sum(1 for _, k, _ in tm._c98_scan_text(text)
                        if k == 'unhonourable-instruction')
pre_hits = sum(1 for _, k, _ in tm._c98_scan_text(PRE)
               if k == 'unhonourable-instruction')
if shipped_hits != 0 or pre_hits <= 0:
    failures.append('R16 vocabulary gate: shipped=%d (want 0), pre-shaped=%d (want >0)'
                    % (shipped_hits, pre_hits))

if failures:
    print('FAILURES')
    for f in failures:
        print(' ', f)
    sys.exit(1)
print('OK')
PY
if grep -q "^OK$" "$SCRATCH/synth.out"; then
    t_pass "synthetic T1 PASS / T2-T4 + T6 + T9-T12 + T15 + T17 + T19-T20 + T22 + T24 BITE / T5 + T7-T8 + T18 SPARE / T13-T14 + T16 SKIP / T21 + T23 + T25 both-directions / R16 vocabulary gate"
else
    t_fail "synthetic PASS/BITE/SPARE cases failed" "$(cat "$SCRATCH/synth.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end --only-check 98 on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: validate-pack.py --only-check 98 on HEAD ===\n"

if (cd "$REPO_ROOT" && python3 "$VALIDATE" --only-check 98 > "$SCRATCH/e2e.out" 2>&1); then
    t_pass "validate-pack.py --only-check 98 exits 0 on HEAD"
else
    t_fail "validate-pack.py --only-check 98 exited non-zero on HEAD" "$(tail -20 "$SCRATCH/e2e.out")"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Results: %d passed, %d failed ===\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
