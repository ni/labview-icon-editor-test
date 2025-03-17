# **Getting Started Guide**

This **Getting Started Guide** introduces a streamlined GitHub Action for **building and releasing** the **LabVIEW Icon Editor**. It automates versioning via **Pull Request labels**, assigns a **build number** based on total commits, optionally **attaches** the built `.vip` to a GitHub Release, and can **disable GPG** signing for forks. In this updated version, we also include sections on **troubleshooting** and an **FAQ** to help you maintain the workflow effectively.

---

## **Table of Contents**

1. [Introduction](#introduction)  
2. [Step-by-Step Procedure](#step-by-step-procedure)  
3. [Detailed Technical Section](#detailed-technical-section)  
4. [Troubleshooting](#troubleshooting)  
5. [FAQ](#faq)

---

<a name="introduction"></a>
## **1. Introduction**

The **LabVIEW Icon Editor CI/CD Workflow** ensures that:
- **Semantic Version Bumps** happen with `major`, `minor`, or `patch` Pull Request labels.
- The **build number** increases with every commit, providing a unique “-buildXXX” suffix.
- The final **`.vip`** artifact can be uploaded to GitHub Actions as an ephemeral artifact, and optionally **attached** to the release.
- Forks can optionally **disable GPG** signing to avoid missing key issues.

By following the instructions below, you can run and maintain this workflow with minimal effort. It’s designed for both first-time maintainers (who can read the Step-by-Step instructions) and experienced users (who can quickly reference the Technical Section for advanced details).

---

<a name="step-by-step-procedure"></a>
## **2. Step-by-Step Procedure**

Below is a **simple** guide for day-to-day usage and maintenance of the Action:

1. **Locate the Workflow File**  
   - Ensure `.github/workflows/build-vi-package.yml` exists in your repository. This is the pipeline definition.

2. **Check Required Permissions**  
   - In your GitHub repository settings, under **Actions**, allow **“Read and Write Permissions”** so the workflow can create tags and releases.

3. **(Optional) Configure Environment Variables**  
   - **`DRAFT_RELEASE`** (`true` or `false`): Toggle draft vs. published releases (default `true`).
   - **`USE_AUTO_NOTES`** (`true` or `false`): Use GitHub’s auto-generated release notes (default `true`).
   - **`ATTACH_ARTIFACTS_TO_RELEASE`** (`true` or `false`): Attach the `.vip` file to the release (default `false`).
   - **`DISABLE_GPG_ON_FORKS`** (`true` or `false`): Disable GPG signing if on a fork (default `false`).
   - You can override these in the workflow `env:` or in your repository’s environment variables.

4. **Make a Pull Request**  
   - If you need a version bump, label your PR as `major`, `minor`, or `patch`.
   - If no label is found, the major/minor/patch version does not change (only the build number increments).

5. **Observe the Build**  
   - The Action checks out your code, detects labels, calculates a build number via total commits, and merges everything into a final version string (e.g. `v1.2.4-build23`).

6. **Merge to `release/*`, `main`, or `hotfix/*`**  
   - **`release/*`** triggers a pre-release suffix: `-rc.<N>`.  
   - **`main`** or **`hotfix/*`** merges yield a final release (no `-rc`).

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

### 3.1 **Environment Variables & Parameters**
- **DRAFT_RELEASE**: If `true`, releases are created in draft mode.  
- **USE_AUTO_NOTES**: If `true`, sets `generate_release_notes: true` on createRelease.  
- **ATTACH_ARTIFACTS_TO_RELEASE**: If `true`, uploads `.vip` to release assets.  
- **DISABLE_GPG_ON_FORKS**: If `true`, the action disables GPG signing on forks.

### 3.2 **Workflow Logic**
1. **Checkout**  
   - Uses `actions/checkout@v3` with `fetch-depth: 0` for a full commit history.
2. **Determine Bump Type**  
   - A pull request label among `major`, `minor`, `patch` increments that field; no label → none.  
   - If not a PR event, fallback is “none” (only build number increments).
3. **Commit-Based Build Number**  
   - `git rev-list --count HEAD` → integer appended as `-build<NN>`.
4. **Pre-Release for `release/*`**  
   - If branch is `release/*`, append `-rc.<N>`. Merging to main yields final (no suffix).
5. **Build Script**  
   - Calls `Build.ps1`, output `.vip` in `builds/VI Package/`.
6. **Tag & Create Release**  
   - On non-PR events, we push a tag `v<major>.<minor>.<patch>-build<NN>`; create a release. If `DRAFT_RELEASE==true`, it’s draft. If `ATTACH_ARTIFACTS_TO_RELEASE==true`, attach `.vip`.

### 3.3 **Maintaining the Build & Release Cycle**
- **Major/Minor/Patch**: Driven by PR labels.
- **No Label**: Only build increments.  
- **Artifacts**: Ephemeral `.vip` artifact expires after a few days unless attached to the release.  
- **Forks**: If you set `DISABLE_GPG_ON_FORKS=true`, no GPG keys needed.

---

<a name="troubleshooting"></a>
## **4. Troubleshooting**

1. **No `.vip` Found**  
   - Ensure your `Build.ps1` actually outputs to `builds/VI Package/*.vip`. If the path is incorrect, the discover step fails.
2. **Invalid URI Errors**  
   - The workflow strips `{?name,label}` from the `upload_url` when attaching artifacts. If you see “Host Not Parsed,” confirm that code is correct.
3. **403 Permission**  
   - Check that your repository’s **Actions** settings → **Workflow permissions** is set to **Read and write**. Also confirm tag creation is allowed in your branch/tag protection rules.
4. **Label Doesn’t Increase Version**  
   - Possibly you’re pushing directly to `main`. Make sure the logic references `pull_request` events for label detection, or manually set a default in the code if needed.

---

<a name="faq"></a>
## **5. FAQ**

1. **Q:** *Can I attach multiple `.vip` files?*  
   **A:** Yes, adapt the “Discover .vip path” step to handle multiple matches, then upload them in the same manner.

2. **Q:** *What if I want `alpha` or `beta` channels instead of `-rc`?*  
   **A:** Modify the logic for branch patterns in “Compute version string” to append `-alpha.<N>` or `-beta.<N>` instead.

3. **Q:** *Is there a manual way to override the build number?*  
   **A:** Not by default. The workflow automatically calculates the build number from total commits for consistency. You could add an optional offset, but it might break linear progression.

4. **Q:** *Does this work on a GitHub-Hosted runner?*  
   **A:** Potentially yes, but you need LabVIEW installed on the runner. Typically you use a self-hosted Windows runner with LabVIEW. If you can create a self-hosted environment that mimics a GitHub-hosted runner, you can do so.

5. **Q:** *What if I want a final release, not a draft?*  
   **A:** Set `DRAFT_RELEASE=false`. Then the release is published immediately after the build completes.

6. **Q:** How do I override build number or forcibly skip a release?  
   **A:** By default, we rely on `git rev-list --count HEAD`. You can change it by passing a custom environment variable or skipping the tag steps.

7. **Q:** Does it support alpha/beta channels out of the box?  
   **A:** You can parse more branch patterns (e.g. `release-alpha/*`) and set a suffix like `-alpha.<N>`. The logic is easily adapted in the “Compute version string” step.

8. **Q:** What about manual triggers?  
   **A:** If `workflow_dispatch` is enabled, you can run it from the Actions tab, typically defaulting to the same logic (`none` for bump).

9. **Q:** Where do I see ephemeral artifacts?  
   **A:** In the Actions run logs. Look for the “Artifacts” section. If you attach the `.vip` to the release, it’s permanent under “Assets” in the Release page.