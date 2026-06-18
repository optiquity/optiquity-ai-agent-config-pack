# Optiquity AI Agent Config Pack License

**Version 1.0 — 2026-05-02**

Copyright © Optiquity, Inc. All rights reserved.

This license governs the use of the **Optiquity AI Agent Config Pack**
(the "Pack") and any modification, fork, or derivative work thereof.
By using, copying, modifying, or distributing the Pack — or any portion
of it — you agree to all terms below.

This is **not** an OSI-approved open source license. It is a
**source-available** license: the source code is published, but use
is subject to the conditions in Section 3.

---

## 1. Definitions

**1.1 "Pack."** The contents of the `optiquity-ai-agent-config-pack`
repository owned by Optiquity, Inc., including (without limitation)
configuration files, agent files, skill files, scripts, documentation,
templates, and any other files distributed in that repository — and
any modification, fork, or derivative work thereof.

**1.2 "You" / "Licensee."** Any individual or legal entity that uses,
copies, modifies, or distributes the Pack.

**1.3 "Modification."** Any change to a Pack-controlled file (including
but not limited to files at the root of the repository, files under
`project-template/`, `supporting-docs/`, `scripts/`, agent files in
`.claude/`, `.codex/`, `.agents/`, and skill files), or any fork of the
Pack as a whole.

**1.4 "Permitted Customization" — not a Modification.** The Pack ships
with explicit customization mechanisms intended to be used by every
project that adopts the Pack. The following are **not** Modifications:

- Filling placeholders such as `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`,
  `[TRANSPORT]`, and similar Pack-defined placeholders with
  project-specific values.
- Creating files prefixed with `x-` in any Pack-controlled location
  per the Pack's documented `x-` prefix convention (custom agents,
  custom skills, custom scripts, custom prompt variants).
- Adding content under the Pack's documented `## Project addenda`
  H2 markers in trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`)
  or PM-CHAT.md.

Permitted Customization remains the property of the Licensee and is
not subject to Section 4. A project built using the Pack via
Permitted Customization is the Licensee's own work; it is not the
Pack and is not subject to this license.

**1.5 "Distribute."** To make available to any third party in any
form — including (without limitation) shipping files, hosting
downloads, bundling into a software product, or providing access
through a network service in a way that exposes Pack content,
behavior, or methodology to that third party.

**1.6 "Public free version."** A copy of the relevant version of
the Pack made available to the general public, downloadable without
payment, registration gating, customer-only access, or any other
barrier to access, with clear attribution to Optiquity, Inc. as the
original owner.

---

## 2. Grant of License

Subject to the conditions in Section 3, Optiquity, Inc. grants You a
worldwide, royalty-free, non-exclusive, non-sublicensable,
non-transferable license to:

- **Use** the Pack for any purpose, commercial or non-commercial.
- **Modify** the Pack to create Modifications.
- **Distribute** the Pack and Modifications, subject to Section 3.

This license is granted directly by Optiquity, Inc. to each
Licensee. It is **not sub-licensable**: anyone wishing to use the
Pack must accept this license directly.

---

## 3. Conditions

### 3.1 No Sale

You may not sell the Pack, charge for the Pack, or charge for any
Modification of the Pack — whether as a standalone product, as part
of a paid service, as part of a subscription, course, training
program, bundled distribution, or any other commercial arrangement.

The Pack must be free wherever it is offered or made available.

### 3.2 Free Public Version Requirement (Distribution Triggered)

If You Distribute the Pack or any Modification — whether as a
standalone download, embedded in a paid product, served through a
web interface or application, or otherwise — You must:

- Publish a Public Free Version of exactly the Pack version You are
  distributing (including all Modifications You have applied).
- Provide a publicly accessible direct download link to that Public
  Free Version. The link must not be hidden behind authentication,
  paywall, signup wall, customer-only gating, geographic restriction,
  or any other barrier to public access.
- Display clear attribution identifying Optiquity, Inc. as the
  original owner of the Pack, in accordance with Section 3.4.

### 3.3 Use in Building Other Projects (No Distribution of Pack
Files)

You may use the Pack to build software, products, services, or other
projects of any kind, including projects offered for sale. The
project You build is Your own work, not the Pack, and is not
subject to this license.

However:

- **You may not include any Pack files (or any portion of any Pack
  file) in a project that is offered for sale, license, lease,
  subscription, or any other paid arrangement** — unless You also
  satisfy Section 3.2 (Public Free Version Requirement) for the
  Pack version embedded.
- Internal use of the Pack inside Your organization (for example,
  by Your employees or contractors developing Your software) is
  **Use**, not Distribution. No public free version is required.
- Operating a paid web service or application that exposes the
  Pack's behavior, content, or methodology to Your customers (for
  example, a product that lets customers interact with Pack-driven
  agents, or that surfaces Pack file contents to customers) **is
  Distribution** and triggers Section 3.2. If a customer using Your
  product can determine that the Pack was involved, You are
  Distributing the Pack and the Public Free Version Requirement
  applies.
- If a customer using Your product cannot determine that the Pack
  was involved, You are using the Pack as an internal tool and
  Section 3.2 does not apply.

### 3.4 Attribution

In every distribution and every public-facing offering of the Pack
or any Modification, You must:

- Retain all references to Optiquity, Inc. as the original owner
  of the Pack — in the LICENSE file, README, file headers, file
  bodies, and anywhere else the original Pack contains such
  references.
- Not add, remove, or alter text in any way that suggests You,
  rather than Optiquity, Inc., own or authored the Pack or any
  Modification.
- When the Pack or any Modification is included in or used to power
  a product, service, or application, credit Optiquity, Inc. in
  the standard place for attribution in that medium — for example,
  the open source / third-party software list on a website, an
  attributions / about screen in a desktop or mobile application,
  or the appropriate metadata field in an app store listing.

### 3.5 No Misattribution / No Ownership Claim

You may not represent — directly, indirectly, or by omission — that
You are the original owner or author of the Pack or any Modification.
You may not strip, replace, or hide attribution to Optiquity, Inc.
You may not relicense the Pack or any Modification under different
terms.

### 3.6 No Sub-licensing; No Custom License

You may not grant any third party rights to the Pack or any
Modification under any license other than this one. Anyone wishing
to use the Pack must accept this license directly from Optiquity,
Inc. (typically by obtaining the Pack from Optiquity's official
repository or a Public Free Version published per Section 3.2).

You may not create or apply Your own license to the Pack or any
Modification, since doing so would imply ownership You do not have
(see Section 4).

---

## 4. Modifications and Forks

### 4.1 Ownership of Modifications

Any Modification You create — including any fork of the Pack, even
if You rename it — is the exclusive property of Optiquity, Inc. By
creating, distributing, or making available any Modification, You
hereby assign to Optiquity, Inc. all right, title, and interest
(including all copyright and other intellectual property rights) in
and to such Modification, effective immediately upon its creation.

You waive any moral rights in the Modification to the maximum extent
permitted by law.

This assignment applies regardless of:

- Whether You publish, distribute, or merely retain the Modification.
- Whether You rename the Pack, the Modification, or any file
  contained in either.
- Whether You apply Your own copyright notice (which You must not
  do — see Section 3.5).

If You wish to retain ownership of a contribution, do not modify the
Pack. The Pack's Permitted Customization mechanisms (Section 1.4)
allow You to build extensively on top of the Pack while retaining
ownership of Your project work.

### 4.2 Mandatory Provision Upon Request

Upon written request from Optiquity, Inc. (including by email to the
contact addresses in the README), You shall, within thirty (30) days,
provide Optiquity, Inc. with the complete source of any Modification
You have created. This obligation applies whether or not You have
distributed the Modification.

Optiquity, Inc. may, but is not obligated to, incorporate any such
Modification into the Pack.

### 4.3 Forks

Any fork of the Pack — including a fork hosted in a different
repository or under a different name — is a Modification and is
subject to all terms of this Section 4 and of this license generally.
Forks remain the property of Optiquity, Inc. They may not be
relicensed, sold, or distributed except in accordance with this
license.

---

## 5. Termination

### 5.1 Termination on Breach

If You breach any term of this license, all rights granted to You
under Section 2 terminate automatically and immediately.

### 5.2 Cure Period for Unintentional Breach

If the breach is unintentional and You cure it within thirty (30)
days of becoming aware of it (whether by notice from Optiquity, Inc.
or otherwise), Your rights are reinstated.

### 5.3 No Cure for Intentional Breach

Intentional breach — including (without limitation) intentional
misattribution, intentional sale of the Pack, or intentional refusal
to provide a Public Free Version where required — is not subject to
the cure period in Section 5.2.

### 5.4 Effect of Termination

Upon termination, You must immediately cease using, copying,
modifying, and distributing the Pack and any Modification. You must
destroy or permanently delete all copies in Your possession or
control. Sections 4 (Modifications and Forks), 6 (Disclaimer), 7
(Liability), 9 (Governing Law), and 10 (General Provisions) survive
termination.

---

## 6. Disclaimer of Warranty

THE PACK IS PROVIDED "AS IS" AND "AS AVAILABLE", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
TITLE, AND NON-INFRINGEMENT. OPTIQUITY, INC. DOES NOT WARRANT THAT
THE PACK WILL BE ERROR-FREE, SECURE, UNINTERRUPTED, OR THAT IT WILL
MEET YOUR REQUIREMENTS.

YOU USE THE PACK AT YOUR SOLE RISK.

---

## 7. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL
OPTIQUITY, INC. (OR ITS OFFICERS, DIRECTORS, EMPLOYEES, AGENTS, OR
AFFILIATES) BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL,
CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, OR FOR ANY LOSS OF
PROFITS, REVENUE, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES,
ARISING OUT OF OR IN CONNECTION WITH YOUR USE OR INABILITY TO USE
THE PACK, EVEN IF OPTIQUITY, INC. HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

OPTIQUITY, INC.'S TOTAL LIABILITY FOR ALL CLAIMS RELATING TO THE
PACK SHALL NOT EXCEED ONE HUNDRED U.S. DOLLARS (USD 100).

---

## 8. Patent Grant and Retaliation

### 8.1 Patent Grant

Subject to the conditions of this license, Optiquity, Inc. grants
You a worldwide, royalty-free, non-exclusive, non-sublicensable
patent license to use, copy, modify, and distribute the Pack —
limited to patent claims owned or controlled by Optiquity, Inc.
that are necessarily infringed by Your use of the Pack as
distributed.

### 8.2 Patent Retaliation

If You initiate or threaten patent litigation (including a
cross-claim or counterclaim) against any entity alleging that the
Pack or any Modification infringes a patent, all rights granted to
You under this license — including the patent grant in Section 8.1
— terminate immediately as of the date such litigation is filed.

---

## 9. Governing Law and Jurisdiction

This license shall be governed by and construed in accordance with
the laws of the State of New York, United States of America, without
regard to its conflict-of-laws principles.

Any dispute arising out of or relating to this license shall be
brought exclusively in the state or federal courts located in New
York County, New York, and You consent to the personal jurisdiction
of those courts.

---

## 10. General Provisions

### 10.1 Versioning

Each tagged release of the Pack is governed by the LICENSE file in
effect at that release tag. Optiquity, Inc. may publish future
versions of this license that apply to subsequent releases of the
Pack. Existing copies retain the license under which they were
released.

### 10.2 No Trademark Grant

This license does not grant rights to use the trade names,
trademarks, service marks, product names, or logos of Optiquity,
Inc. — except as strictly required by Section 3.4 (Attribution).
Trademark policies, if any, are governed separately.

### 10.3 No Waiver

Failure by Optiquity, Inc. to enforce any provision of this license
is not a waiver of that provision or any other.

### 10.4 Severability

If any provision of this license is held unenforceable, the
remaining provisions remain in full force and effect, and the
unenforceable provision shall be modified to the minimum extent
necessary to make it enforceable while preserving its intent.

### 10.5 Entire Agreement

This license constitutes the entire agreement between You and
Optiquity, Inc. regarding the Pack and supersedes any prior
agreements, written or oral, on the same subject matter.

### 10.6 Contact

For requests under Section 4.2, license questions, or any other
matter under this license, contact:

- Email: config-pack@optiquity.com
- Web:   https://optiquity.com

---

**End of License.**
