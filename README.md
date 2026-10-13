# Delete-Github-Action-Workflow-Runs

PowerShell script to delete GitHub Actions workflow runs for a selected workflow.

## Important

Run `Delete-WorkflowRuns.ps1` from the **root of your GitHub project**.

The script looks for:

- The current repository by using `gh repo view`
- Workflow files in `.github\workflows`

When you run it from the repository root, it can automatically detect the repository and list the available workflow `.yml` or `.yaml` files for you to choose from.

If you run it outside the repository root, the script may not detect the repository or workflow files, and you will need to enter the repository name and workflow filename manually.

## Requirements

- [GitHub CLI](https://cli.github.com/) installed
- GitHub CLI authenticated with `gh auth login`
- A GitHub repository that contains workflow files in `.github\workflows`

## Usage

From the root of your GitHub project, run:

```powershell
.\Delete-WorkflowRuns.ps1
```

## What the script does

1. Checks whether GitHub CLI is authenticated
2. Detects the current repository when possible
3. Reads workflow files from `.github\workflows`
4. Prompts you to select a workflow by number or filename
5. Deletes all runs for that workflow in batches until none remain

## Warning

This permanently deletes workflow runs for the selected workflow. Use care before confirming the repository and workflow selection.
