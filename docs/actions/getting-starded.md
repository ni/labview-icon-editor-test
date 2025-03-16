
# ** Getting Started Guide**

This **Getting Started Guide** introduces a streamlined GitHub Action for building and releasing the **LabVIEW Icon Editor**. It automates versioning via **Pull Request labels**, assigns a **build number** based on total commits, optionally **attaches** the built `.vip` to a GitHub Release, and can **disable GPG** signing for forks.

---

## **Table of Contents**

1. [Introduction](#introduction)  
2. [Step-by-Step Procedure](#step-by-step-procedure)  
3. [Detailed Technical Section](#detailed-technical-section)  
   - [Environment Variables & Parameters](#environment-variables--parameters)  
   - [Workflow Logic](#workflow-logic)  
   - [Maintaining the Build & Release Cycle](#maintaining-the-build--release-cycle)

---

<a name="introduction"></a>
## **1. Introduction**

The **LabVIEW Icon Editor CI/CD Workflow** ensures that:
- **Semantic Version Bumps** happen with `major`, `minor`, or `patch` Pull Request labels.  
- The **build number** increases with every commit, providing a unique “-buildXXX” suffix.  
- The final **`.vip`** artifact can be uploaded to GitHub Actions as an ephemeral artifact, and optionally **attached** to the release.  
- Forks can optionally **disable** GPG signing to avoid missing key issues.

By following the instructions below, you can run and maintain this workflow with minimal effort. It’s designed for both first-time maintainers (who can read the Step-by-Step instructions) and experienced users (who can quickly reference the Technical Section for advanced details).

---

<a name="step-by-step-procedure"></a>
## **2. Step-by-Step Procedure**

Below is a **simple** guide for day-to-day usage and maintenance of the Action:

1. **Locate the Workflow File**  
   - Ensure `.github/workflows/build-vi-package.yml` exists in your repository. This is the pipeline definition.

2. **Check Required Permissions**  
   - In your GitHub repository settings, under **Actions**, allow “Read and Write Permissions” so the workflow can create tags and releases.

3. **(Optional) Configure Environment Variables**  
   - `DRAFT_RELEASE`: `true` or `false` (Draft release vs. published).  
   - `USE_AUTO_NOTES`: `true` or `false` (Use GitHub’s auto-generated release notes).  
   - `ATTACH_ARTIFACTS_TO_RELEASE`: `true` or `false` (Attach the `.vip` to the release).  
   - `DISABLE_GPG_ON_FORKS`: `true` or `false` (Disable GPG signing if it’s a fork).  
   - You can override these in the workflow `env:` or in your repository’s environment variables.

4. **Make a Pull Request**  
   - If you need a version bump, label your PR as `major`, `minor`, or `patch`.  
   - If no label is found, the major/minor/patch version does not change (only the build number increments).

5. **Observe the Build**  
   - The Action checks out your code, detects labels, calculates a build number via total commits, and merges everything into a final version string (e.g. `v1.2.4-build23`).

6. **Merge to `release/*`, `main`, or `hotfix/*`**  
   - `release/*` triggers a pre-release suffix: `-rc.<N>`.  
   - `main` or `hotfix/*` merges yield a final release (no `-rc`).

7. **Confirm Artifacts and Release**  
   - The `.vip` file is uploaded as an ephemeral artifact. If `ATTACH_ARTIFACTS_TO_RELEASE` is `true`, that `.vip` is also attached to the GitHub Release.  
   - By default, the Release is in draft mode (`DRAFT_RELEASE=true`), so you can finalize it at your convenience. 

8. **(Optional) Manage GPG**  
   - If `DISABLE_GPG_ON_FORKS==true` and this is a fork, the workflow automatically turns off commit/tag signing. It re-enables them at the end.

9. **Review or Publish the Release**  
   - If it’s draft, you can go to the Releases page, edit the notes or add attachments manually, then publish.

This procedure keeps your **LabVIEW Icon Editor** build process consistent and easy to maintain across merges, pre-releases, and final versions.

---

<a name="detailed-technical-section"></a>
## **3. Detailed Technical Section**

The following gives experienced users a **concise reference** for how each major piece works, so they can quickly adapt or troubleshoot.

<a name="environment-variables--parameters"></a>
### 3.1 Environment Variables & Parameters

- **DRAFT_RELEASE (bool)**:  
  - Default `true`. If `true`, the `createRelease` step sets `draft: true`.  
  - If `false`, the release publishes automatically upon success.

- **USE_AUTO_NOTES (bool)**:  
  - Default `true`. If `true`, the workflow calls GitHub’s `generate_release_notes: true`, producing notes from merged PRs.  
  - If `false`, we provide a basic body or rely on local documentation.

- **ATTACH_ARTIFACTS_TO_RELEASE (bool)**:  
  - Default `false`. If `true`, after building the `.vip` file, the workflow attaches it to the GitHub Release using a direct REST call (`Invoke-RestMethod`).

- **DISABLE_GPG_ON_FORKS (bool)**:  
  - Default `false`. If `true`, we check `github.repository` for mismatch with official repo name. If it’s a fork, `commit.gpgsign` and `tag.gpgsign` are disabled, then restored.

<a name="workflow-logic"></a>
### 3.2 Workflow Logic

1. **Checkout**  
   - We do `actions/checkout@v3` with `fetch-depth: 0` so we have full commit history for counting.

2. **Determine Bump Type**  
   - If event is a pull request, parse labels for `major`, `minor`, `patch`; otherwise, `none`.  
   - `major` → `major++`, `minor=0`, `patch=0`.  
   - `minor` → `minor++`, `patch=0`.  
   - `patch` → `patch++`.  
   - `none` → no change in major/minor/patch.

3. **Commit-Based Build Number**  
   - Run `git rev-list --count HEAD` to produce an integer. This is appended as `-build<CommitCount>`.

4. **Pre-Release for `release/*`**  
   - If the branch is named `release/*`, we add `-rc.<N>` by counting commits from `develop` or HEAD.  
   - Merging back to `main` finalizes it.

5. **Build Script & .vip Creation**  
   - The script is `Build.ps1`. We pass `-Major`, `-Minor`, `-Patch`, `-Build`, and `-Commit`.  
   - A `.vip` file ends up in `builds/VI Package/*.vip`.

6. **Ephemeral Artifact**  
   - By default, we upload the `.vip` to GitHub Actions. It remains accessible from the run logs.  
   - If `ATTACH_ARTIFACTS_TO_RELEASE: true`, we also attach that `.vip` to the release using the release’s `upload_url`.

7. **Tag & Release**  
   - If not a pull_request, we create an annotated tag `v<Major>.<Minor>.<Patch>-build<BuildNum>` (plus any `-rc` suffix).  
   - Then `createRelease` on GitHub. If `DRAFT_RELEASE=true`, it remains in draft.

<a name="maintaining-the-build--release-cycle"></a>
### 3.3 Maintaining the Build & Release Cycle

- **Major/Minor Changes**  
  - Simply label your PR `major` or `minor`, so the next merge increments accordingly.  
  - If you push directly to `main` without a label, `none` means the version remains e.g. `v1.2.3`, only build increments.

- **CI Logs & Artifacts**  
  - The ephemeral artifact (the `.vip`) automatically expires after some days. If you want permanent storage, set `ATTACH_ARTIFACTS_TO_RELEASE=true`, ensuring the `.vip` is part of the Release assets.

- **Version Consistency**  
  - Because we base build number on total commits, it increments linearly for each new commit. Avoid rebasing or force-pushing if you want a strictly increasing sequence.

- **Fork Collaboration**  
  - If a contributor forks your repo, you can keep `DISABLE_GPG_ON_FORKS=true` so the contributor’s build doesn’t fail from missing GPG keys. It’s automatically turned off again at the end of the run.

---

<a name="troubleshooting"></a>
## **4. Troubleshooting**

1. **“No .vip Found in `builds/VI Package`”**  
   - Ensure your `Build.ps1` script places the final `.vip` exactly in `builds/VI Package`. If the path differs, the action can’t find it.

2. **“Invalid URI” or “Host Not Parsed”**  
   - Happens if the `upload_url` for your release includes `{?name,label}`. The action strips it out by splitting on `{`. If your repo name changes or environment differs, verify the string manipulation logic in the “Attach .vip to Release” step.

3. **403 Permission Denied**  
   - Make sure the action has `contents: write` permission under **Repo → Settings → Actions**. Also confirm `GITHUB_TOKEN` is not restricted.

4. **Version Not Updating**  
   - Possibly no PR label was found (the action sets “none” as the bump type), so only the build changes. Label your PR `patch` if you want patch increments.

5. **Mismatched GPG Logic**  
   - If you have GPG keys in your fork, either set `DISABLE_GPG_ON_FORKS=false` or remove that step. 

---

<a name="faq"></a>
## **5. FAQ**

1. **How Can I Force a Draft vs. Published Release?**  
   - Set `DRAFT_RELEASE` to `true` or `false` in the workflow `env:` block. If `true`, you’ll see a draft release ready for finalization.

2. **Can I Upload Multiple `.vip` Files or Additional Artifacts?**  
   - Yes, you can adapt the “Discover .vip path” step to handle multiple matching files. Then attach them in the same way.

3. **What If I Need More Pre-Release Channels (alpha, beta)?**  
   - Adjust the logic for `branchName` or add custom detection in the “Compute version string” step. For example, `release-alpha/*` → `-alpha.<N>`, etc.

4. **Is Manual Overriding of Build Number Possible?**  
   - Not by default. We rely on `git rev-list --count HEAD` for a strictly linear progression. You could add an environment variable offset if desired, but it may complicate version continuity.

5. **Does This Work for Windows, Mac, or Linux Runners?**  
   - The steps use PowerShell scripts. Typically works on Windows self-hosted runners. For Linux or Mac, adapt the `.ps1` calls or ensure the runner has PowerShell installed.

This **Revision Alpha** approach to the LabVIEW Icon Editor CI/CD Workflow ensures a robust, **commit-based** build number, straightforward label-based semantic version bumps, optional GPG logic for forks, and an easy toggle to attach the `.vip` artifact to your GitHub Releases. If you follow the steps above, you can easily maintain and extend this pipeline to suit future needs.


