# Local CI/CD Workflows (Multi-Channel Release Support)

This document explains how to automate build, test, and distribution steps for the Icon Editor using GitHub Actions, now **supporting multiple pre-release channels** (Alpha, Beta, RC). It includes features such as **fork-friendly GPG signing** toggles, **automatic version bumping** (using PR labels), and the **release creation** process.  

With **multi-channel** support, branches named `release-alpha/*`, `release-beta/*`, or `release-rc/*` will produce pre-release versions (e.g., `-alpha.<N>`, `-beta.<N>`, `-rc.<N>`). Merging to main yields a final release.



## Table of Contents

1. [Introduction](#1-introduction)  
2. [Quickstart](#2-quickstart)  
3. [Getting Started](#3-getting-started)  
   1. [Development vs. Testing](#31-development-vs-testing)  
   2. [Available CI Workflows](#32-available-ci-workflows)  
   3. [Setting Up a Self-Hosted Runner](#33-setting-up-a-self-hosted-runner)  
   4. [Running the Actions Locally](#34-running-the-actions-locally)  
   5. [Example Developer Workflow](#35-example-developer-workflow)



<a name="1-introduction"></a>
## 1. Introduction

Automating your Icon Editor builds and tests:
- Provides consistent steps for every commit or pull request
- Minimizes manual toggling of LabVIEW environment settings
- Stores build artifacts (VI Packages) in GitHub for easy download
- **Automatically versions releases** using label-based semantic logic and **commit-based** build numbers
- Supports **multiple pre-release channels** (alpha, beta, rc) by detecting branch names (`release-alpha/*`, `release-beta/*`, `release-rc/*`)
- Handles GPG signing in the main repo but **disables** it for forks (so fork owners aren’t blocked by passphrase prompts)

**Prerequisites**:  
- LabVIEW 2021 SP1 (32 and 64-bit)  
- PowerShell 7+  
- Git for Windows  

For more details on the multi-channel release branching pattern, see **docs/ci/actions/multichannel-release-workflow.md**.



<a name="2-quickstart"></a>
## 2. Quickstart

1. **Install PowerShell & Git**  
   Ensure your environment has the required tools (plus LabVIEW) before setting up the workflows.

2. **Configure a Self-Hosted Runner**  
   Under **Settings → Actions → Runners** in your GitHub repo, add a runner with LabVIEW installed. Label it as `self-hosted, iconeditor` (or adjust the workflows accordingly).

3. **Enable/Disable Development Mode**  
   You can toggle Development Mode either via the “Development Mode Toggle” workflow or manually. Development Mode modifies `labview.ini` to reference your local source code.

4. **Run Unit Tests**  
   Use the **Run Unit Tests** workflow to confirm your environment is valid. Typically run with Dev Mode **disabled** unless you’re testing dev features specifically.

5. **Build VI Package & Release** (Multi-Channel)  
   - Produces `.vip` artifacts automatically.  
   - Uses **label-based** version bumping (major/minor/patch) on PRs or `none` if unlabeled.  
   - Appends `-buildN` from total commits.  
   - Detects branch name for pre-release channels:  
     - `release-alpha/*` → `-alpha.<N>`  
     - `release-beta/*` → `-beta.<N>`  
     - `release-rc/*` → `-rc.<N>`  
   - Creates tags and releases for direct pushes (not for PRs), with GPG signing disabled if fork.

6. **Disable Dev Mode** (optional)  
   Reverts your environment to normal LabVIEW settings, removing local overrides.



<a name="3-getting-started"></a>
## 3. Getting Started

### 3.1 Development vs. Testing

- **Development Mode**:  
  A specialized configuration where LabVIEW references local paths for the Icon Editor code. Useful for debugging or certain dev features. Enable via `Set_Development_Mode.ps1` or the **Development Mode Toggle** workflow.

- **Testing / Distributable Builds**:  
  Typically done in **normal** LabVIEW mode. If you forget to disable Dev Mode, tests or builds might rely on your local dev environment in unexpected ways.



### 3.2 Available CI Workflows

1. **[Development Mode Toggle]**  
   - Invokes `Set_Development_Mode.ps1` or `RevertDevelopmentMode.ps1`.  
   - Usually triggered via `workflow_dispatch`.

2. **[Build and Release VI Package (Multi-Channel)]**  
   - **Automatically** versions your code based on PR labels (`major`, `minor`, `patch`).  
   - Uses a **commit-based** build number: `vX.Y.Z[-pre.<N>]-build<commitCount>`.  
   - Detects **alpha/beta/rc** branches for multiple pre-release channels:  
     - `release-alpha/*` → `-alpha.<N>`  
     - `release-beta/*` → `-beta.<N>`  
     - `release-rc/*` → `-rc.<N>`  
   - **Fork-Friendly**: Disables GPG signing if it’s not the main repo.  
   - Produces `.vip` artifacts, optionally attaches them to the GitHub Release if `ATTACH_ARTIFACTS_TO_RELEASE == true`.

3. **[Run Unit Tests]**  
   - Executes `unit_tests.ps1` in `pipeline/scripts`.  
   - Typically expects Dev Mode **disabled**.



### 3.3 Setting Up a Self-Hosted Runner

1. **Install Prerequisites**  
   - LabVIEW 2021 SP1  
   - PowerShell 7+  
   - Git for Windows

2. **Add Self-Hosted Runner**  
   - Go to **Settings → Actions → Runners** in your GitHub repository. Follow instructions to register a runner on a Windows machine with LabVIEW installed.

3. **Label the Runner**  
   - For example, `self-hosted, iconeditor`.  
   - The workflow’s `runs-on` references these labels to ensure it picks the correct environment.



### 3.4 Running the Actions Locally

1. **Enable Development Mode** (if you need local dev references).  
2. **Run Unit Tests**:  
   - Either the Run Unit Tests workflow or `unit_tests.ps1`.  
3. **Build VI Package**:  
   - Manually call `Build.ps1` or rely on the GitHub Actions workflow to do it for you.  
4. **Disable Dev Mode** if you plan to install the `.vip` normally.



### 3.5 Example Developer Workflow

**Scenario**: You want to implement a new feature, test it, and produce a `.vip` in a multi-channel approach:

1. **Create a feature branch** off `develop`.  
2. **Label your PR** with `minor` if it’s a small feature (no label → no major/minor/patch bump).  
3. **Merge** your PR into a pre-release branch:
   - `release-alpha/2.0` if it’s early alpha,
   - `release-beta/2.0` if it’s a later beta,
   - `release-rc/2.0` for near-final.  
4. The workflow detects `release-alpha/*` and appends `-alpha.<N>-build<commitCount>`.  
5. After merging from alpha → beta → rc → main, you end up with a final version like `v2.0.0-build123`.



**Notes**:

- This multi-channel logic is spelled out in more detail at [docs/ci/actions/multichannel-release-workflow.md](docs/ci/actions/multichannel-release-workflow.md).
- The ephemeral `.vip` artifact is downloadable from Actions. If `ATTACH_ARTIFACTS_TO_RELEASE == true`, it’s permanently in the GitHub Release assets.
- If you’re in a fork, GPG signing is off to avoid passphrase issues. In the main repo, it remains on if keys are configured.

