# Individual Contributor License Agreement

**k-budget — Version 1.0**

Thank you for your interest in k-budget (the "Project"), maintained by
Kelly SOSSOE (the "Maintainer").

To clarify the intellectual property licence granted with Contributions from
any person or entity, the Maintainer must have on file a signed Contributor
Licence Agreement ("Agreement") from each Contributor, indicating agreement
with the terms below. **This agreement protects you as a Contributor as much as
it protects the Project and its users. It does not change your right to use
your own Contributions for any other purpose.**

This document is adapted from the Apache Software Foundation Individual
Contributor License Agreement V2.2, with the changes described in
[What differs from the Apache ICLA](#what-differs-from-the-apache-icla).

## How to sign

You do not need to print, sign or email anything. When you open your first pull
request, an automated check will ask you to post the following comment on that
pull request:

```
I have read the CLA Document and I hereby sign the CLA
```

Your GitHub username, the date and the pull request number are then recorded in
`signatures/version1/cla.json` in this repository. You sign once; later
contributions are covered automatically.

## What you agree to

You accept and agree to the following terms and conditions for Your
Contributions (present and future) that you submit to the Project.

**In return, the Maintainer agrees that Your Contributions will remain
available under a licence approved by the Open Source Initiative.** A future
relicensing may change which licence applies, but it will not withdraw Your
Contributions from free software, and it will not make them available under
proprietary terms only.

Except for the licence granted herein to the Maintainer and to recipients of
software distributed by the Maintainer, You reserve all right, title, and
interest in and to Your Contributions.

### 1. Definitions

**"You"** (or **"Your"**) means the copyright owner, or the legal entity
authorised by the copyright owner, entering into this Agreement with the
Maintainer. For legal entities, the entity making a Contribution and all other
entities that control, are controlled by, or are under common control with that
entity are considered to be a single Contributor. For the purposes of this
definition, "control" means (i) the power, direct or indirect, to cause the
direction or management of such entity, whether by contract or otherwise, or
(ii) ownership of fifty percent (50%) or more of the outstanding shares, or
(iii) beneficial ownership of such entity.

**"Contribution"** means any original work of authorship, including any
modifications or additions to an existing work, that is intentionally submitted
by You to the Project for inclusion in, or documentation of, the Project (the
"Work"). For the purposes of this definition, "submitted" means any form of
electronic, verbal, or written communication sent to the Maintainer or the
Project's representatives, including but not limited to communication on
electronic mailing lists, source code control systems, and issue tracking
systems that are managed by, or on behalf of, the Project for the purpose of
discussing and improving the Work, but excluding communication that is
conspicuously marked or otherwise designated in writing by You as
**"Not a Contribution"**.

**"Work"** means the whole of the Project, across both of its licensing
scopes: the directories `api/` and `app/`, distributed under the GNU Affero
General Public License v3.0, and the directory `flutter/`, distributed under
the Mozilla Public License 2.0. This Agreement applies to Contributions to
either scope.

### 2. Grant of Copyright Licence

Subject to the terms and conditions of this Agreement, You hereby grant to the
Maintainer and to recipients of software distributed by the Maintainer a
perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable
copyright licence to reproduce, prepare derivative works of, publicly display,
publicly perform, sublicense, and distribute Your Contributions and such
derivative works.

### 3. Grant of Patent Licence

Subject to the terms and conditions of this Agreement, You hereby grant to the
Maintainer and to recipients of software distributed by the Maintainer a
perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable
(except as stated in this section) patent licence to make, have made, use,
offer to sell, sell, import, and otherwise transfer the Work, where such
licence applies only to those patent claims licensable by You that are
necessarily infringed by Your Contribution(s) alone or by combination of Your
Contribution(s) with the Work to which such Contribution(s) was submitted. If
any entity institutes patent litigation against You or any other entity
(including a cross-claim or counterclaim in a lawsuit) alleging that Your
Contribution, or the Work to which You have contributed, constitutes direct or
contributory patent infringement, then any patent licences granted to that
entity under this Agreement for that Contribution or Work shall terminate as of
the date such litigation is filed.

### 4. Right to grant

You represent that You are legally entitled to grant the above licence. If Your
employer(s) has rights to intellectual property that You create that includes
Your Contributions, You represent that You have received permission to make
Contributions on behalf of that employer, that Your employer has waived such
rights for Your Contributions to the Project, or that Your employer has
executed a separate agreement with the Maintainer.

### 5. Originality

You represent that each of Your Contributions is Your original creation (see
section 7 for submissions on behalf of others). You represent that Your
Contribution submissions include complete details of any third-party licence or
other restriction (including, but not limited to, related patents and
trademarks) of which You are personally aware and which are associated with any
part of Your Contributions.

### 6. No support, no warranty

You are not expected to provide support for Your Contributions, except to the
extent You desire to provide support. You may provide support for free, for a
fee, or not at all. Unless required by applicable law or agreed to in writing,
You provide Your Contributions on an **"AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND**, either express or implied, including, without
limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT,
MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE.

### 7. Work that is not Your own

Should You wish to submit work that is not Your original creation, You may
submit it to the Project separately from any Contribution, identifying the
complete details of its source and of any licence or other restriction
(including, but not limited to, related patents, trademarks, and licence
agreements) of which You are personally aware, and conspicuously marking the
work as **"Submitted on behalf of a third-party: [named here]"**.

### 8. Notification

You agree to notify the Maintainer of any facts or circumstances of which You
become aware that would make these representations inaccurate in any respect.

## What differs from the Apache ICLA

This document follows the Apache ICLA V2.2 closely. Three changes were made,
and they are stated here rather than left to be discovered:

1. **The counterparty is a person, not a foundation.** The Apache ICLA is
   balanced by the Foundation's commitment to act consistently with its
   non-profit status. A single maintainer cannot make that commitment. It is
   replaced by an explicit undertaking: Your Contributions will remain
   available under an OSI-approved licence.
2. **The Work spans two licences.** Section 1 names both scopes, so that
   signing once covers a contribution to either the AGPL part or the MPL part.
3. **Signing is done on the pull request**, not by emailing a signed PDF. No
   postal address or handwritten signature is collected — only what GitHub
   already exposes: your username, and the date and number of the pull request.

## Why this Project asks for a CLA

A CLA is sometimes viewed with suspicion, because it allows the maintainer to
relicense contributed code. That concern is legitimate and deserves a direct
answer.

k-budget is maintained by one person. Two situations make relicensing a
realistic need rather than a theoretical one:

- **Store conditions can change.** `flutter/` is under MPL-2.0 precisely
  because Apple's terms are incompatible with the AGPL — VLC was pulled from
  the App Store in 2011 for that reason. If those terms tighten again, the
  Project must be able to respond.
- **Sustainability.** Keeping the option of a differently licensed hosted
  offering open is what may allow the Project to continue to exist.

Without a CLA, both doors close permanently the moment the first external
contribution is merged, because relicensing would then require the written
agreement of every contributor — including those who have become unreachable.

**The CLA exists so the Project can adapt, not to appropriate your work.** You
keep every right to your Contributions, and the undertaking above prevents them
from being withdrawn from free software.

---

> This document describes licensing terms. It is not legal advice, and it has
> not been reviewed by a lawyer.
