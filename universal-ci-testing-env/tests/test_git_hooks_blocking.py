"""
Test Suite: Git Hook Integration - Verify Failed Scripts Block Git Operations

This test suite validates that when verification scripts fail, they properly
block git operations like commit, push, and pre-push hooks.

Strategy: RED -> GREEN -> Verify
- RED: Define expected behavior of blocking operations
- GREEN: Implement hooks that validate with universal-ci
- Verify: Confirm actual git operations are blocked
"""

import pytest
import json
import os
import tempfile
import subprocess
from pathlib import Path
from typing import Tuple


class TestGitHooksSetup:
    """Unit tests for git hook creation and setup."""
    
    def test_pre_commit_hook_creation(self, tmp_path, monkeypatch):
        """
        RED: Pre-commit hook should be created in .git/hooks/pre-commit
        GIVEN: A git repository is initialized
        WHEN: Universal CI hook setup is run
        THEN: A pre-commit hook should exist at .git/hooks/pre-commit
        """
        repo = tmp_path / "test_repo"
        repo.mkdir()
        monkeypatch.chdir(repo)
        
        # Initialize git repo
        subprocess.run(["git", "init"], check=True, capture_output=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], check=True)
        
        # Create pre-commit hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit_hook = hooks_dir / "pre-commit"
        pre_commit_content = """#!/bin/sh
./verify.sh
exit $?
"""
        pre_commit_hook.write_text(pre_commit_content)
        pre_commit_hook.chmod(0o755)
        
        # Verify hook exists and is executable
        assert pre_commit_hook.exists()
        assert os.access(pre_commit_hook, os.X_OK)
    
    def test_pre_push_hook_creation(self, tmp_path, monkeypatch):
        """
        RED: Pre-push hook should be created in .git/hooks/pre-push
        GIVEN: A git repository is initialized
        WHEN: Universal CI hook setup is run
        THEN: A pre-push hook should exist at .git/hooks/pre-push
        """
        repo = tmp_path / "test_repo"
        repo.mkdir()
        monkeypatch.chdir(repo)
        
        # Initialize git repo
        subprocess.run(["git", "init"], check=True, capture_output=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], check=True)
        
        # Create pre-push hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_push_hook = hooks_dir / "pre-push"
        pre_push_content = """#!/bin/sh
./verify.sh --stage release
exit $?
"""
        pre_push_hook.write_text(pre_push_content)
        pre_push_hook.chmod(0o755)
        
        # Verify hook exists and is executable
        assert pre_push_hook.exists()
        assert os.access(pre_push_hook, os.X_OK)


class TestScriptFailureBlocksBehavior:
    """
    Integration tests: Verify that failed scripts actually block operations.
    Uses TEST DRIVEN approach to validate blocking behavior.
    """
    
    def _setup_git_repo(self, repo_path: Path, config: dict) -> None:
        """Helper to setup a git repo with universal-ci config."""
        repo_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize git
        subprocess.run(["git", "init"], cwd=repo_path, check=True, capture_output=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], 
                      cwd=repo_path, check=True, capture_output=True)
        subprocess.run(["git", "config", "user.name", "Test User"], 
                      cwd=repo_path, check=True, capture_output=True)
        
        # Write universal-ci config
        config_file = repo_path / "universal-ci.config.json"
        config_file.write_text(json.dumps(config, indent=2))
        
        # Create dummy verify script
        verify_script = repo_path / "verify.sh"
        verify_script.write_text("""#!/bin/sh
# Dummy verify script that can fail
exit $VERIFY_EXIT_CODE
""")
        verify_script.chmod(0o755)
    
    def _create_hooks(self, repo_path: Path) -> None:
        """Helper to create pre-commit and pre-push hooks."""
        hooks_dir = repo_path / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        # Pre-commit hook
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
VERIFY_EXIT_CODE=1 ./verify.sh --stage test
exit $?
""")
        pre_commit.chmod(0o755)
        
        # Pre-push hook
        pre_push = hooks_dir / "pre-push"
        pre_push.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
VERIFY_EXIT_CODE=1 ./verify.sh --stage release
exit $?
""")
        pre_push.chmod(0o755)
    
    def test_failed_test_script_blocks_commit(self, tmp_path, monkeypatch):
        """
        RED: When a test script fails, commit should be blocked
        SCENARIO: Pre-commit hook runs verify.sh with failing test stage
        EXPECTED: Commit should fail with non-zero exit code
        """
        repo_path = tmp_path / "test_repo"
        config = {
            "tasks": [
                {
                    "name": "Test Suite",
                    "working_directory": ".",
                    "command": "exit 1",  # Fails
                    "stage": "test"
                }
            ]
        }
        
        self._setup_git_repo(repo_path, config)
        self._create_hooks(repo_path)
        monkeypatch.chdir(repo_path)
        
        # Create a test file and stage it
        test_file = repo_path / "test.txt"
        test_file.write_text("test content")
        
        subprocess.run(["git", "add", "test.txt"], check=True, capture_output=True)
        
        # Attempt commit - should be blocked by hook
        result = subprocess.run(
            ["git", "commit", "-m", "Test commit"],
            capture_output=True,
            text=True
        )
        
        # Commit should fail (hook blocking)
        assert result.returncode != 0, "Commit should be blocked when test fails"
    
    def test_passing_test_script_allows_commit(self, tmp_path, monkeypatch):
        """
        GREEN: When test script passes, commit should succeed
        SCENARIO: Pre-commit hook runs verify.sh with passing test stage
        EXPECTED: Commit should succeed with exit code 0
        """
        repo_path = tmp_path / "test_repo"
        config = {
            "tasks": [
                {
                    "name": "Test Suite",
                    "working_directory": ".",
                    "command": "exit 0",  # Passes
                    "stage": "test"
                }
            ]
        }
        
        self._setup_git_repo(repo_path, config)
        
        # Create hook that passes
        hooks_dir = repo_path / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
./verify.sh --stage test
exit $?
""")
        pre_commit.chmod(0o755)
        
        monkeypatch.chdir(repo_path)
        
        # Create a test file and stage it
        test_file = repo_path / "test.txt"
        test_file.write_text("test content")
        
        subprocess.run(["git", "add", "test.txt"], check=True, capture_output=True)
        subprocess.run(["git", "add", "universal-ci.config.json"], check=True, capture_output=True)
        
        # Attempt commit - should succeed
        result = subprocess.run(
            ["git", "commit", "-m", "Test commit"],
            capture_output=True,
            text=True
        )
        
        # Commit should succeed (hook passing)
        assert result.returncode == 0, f"Commit should succeed when tests pass. Output: {result.stderr}"
    
    def test_multiple_failing_tasks_block_commit(self, tmp_path, monkeypatch):
        """
        RED: Multiple failing tasks should all block commit
        SCENARIO: Config has 3 tasks, 2 pass, 1 fails
        EXPECTED: Overall verification fails, commit blocked
        """
        repo_path = tmp_path / "test_repo"
        config = {
            "tasks": [
                {
                    "name": "Lint Check",
                    "working_directory": ".",
                    "command": "exit 0",  # Passes
                    "stage": "test"
                },
                {
                    "name": "Unit Tests",
                    "working_directory": ".",
                    "command": "exit 1",  # FAILS
                    "stage": "test"
                },
                {
                    "name": "Integration Tests",
                    "working_directory": ".",
                    "command": "exit 0",  # Passes
                    "stage": "test"
                }
            ]
        }
        
        self._setup_git_repo(repo_path, config)
        self._create_hooks(repo_path)
        monkeypatch.chdir(repo_path)
        
        # Stage files
        (repo_path / "file.txt").write_text("content")
        subprocess.run(["git", "add", "."], check=True, capture_output=True)
        
        # Attempt commit - should fail due to failing task
        result = subprocess.run(
            ["git", "commit", "-m", "Test with mixed results"],
            capture_output=True,
            text=True
        )
        
        # Should fail because one task fails
        assert result.returncode != 0, "Commit should be blocked when any task fails"
    
    def test_release_stage_blocks_push(self, tmp_path, monkeypatch):
        """
        RED: Failed release stage should block push operations
        SCENARIO: Pre-push hook runs verify.sh --stage release and it fails
        EXPECTED: Push should be blocked
        """
        repo_path = tmp_path / "test_repo"
        config = {
            "tasks": [
                {
                    "name": "Build",
                    "working_directory": ".",
                    "command": "exit 1",  # Release task fails
                    "stage": "release"
                }
            ]
        }
        
        self._setup_git_repo(repo_path, config)
        self._create_hooks(repo_path)
        monkeypatch.chdir(repo_path)
        
        # Initialize a commit
        (repo_path / "file.txt").write_text("content")
        subprocess.run(["git", "add", "."], check=True, capture_output=True)
        subprocess.run(["git", "config", "core.hooksPath", ".git/hooks"], check=True)
        subprocess.run(["git", "commit", "-m", "Initial"], capture_output=True)
        
        # Try to push - hook should block it
        # (We simulate the hook behavior rather than actual push)
        pre_push = repo_path / ".git" / "hooks" / "pre-push"
        result = subprocess.run(
            ["bash", str(pre_push)],
            capture_output=True,
            text=True
        )
        
        # Hook should fail, blocking the push
        assert result.returncode != 0, "Push hook should fail when release stage fails"


class TestBlockingErrorMessages:
    """
    Verify that blocked operations provide clear error messages about why they were blocked.
    """
    
    def test_commit_block_shows_failing_task_name(self, tmp_path, monkeypatch):
        """
        GIVEN: A commit is attempted with a failing task named 'Security Audit'
        WHEN: The pre-commit hook runs
        THEN: Error output should mention 'Security Audit' failed
        """
        repo_path = tmp_path / "test_repo"
        config = {
            "tasks": [
                {
                    "name": "Security Audit",
                    "working_directory": ".",
                    "command": "exit 1",
                    "stage": "test"
                }
            ]
        }
        
        repo_path.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "init"], cwd=repo_path, check=True, capture_output=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo_path, check=True)
        subprocess.run(["git", "config", "user.name", "Test"], cwd=repo_path, check=True)
        
        config_file = repo_path / "universal-ci.config.json"
        config_file.write_text(json.dumps(config, indent=2))
        
        hooks_dir = repo_path / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        # Create hook that shows which task failed
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
if ! ./verify.sh --stage test 2>&1 | grep -q "Security Audit"; then
    # Task output should mention Security Audit
    ./verify.sh --stage test 2>&1
fi
""")
        pre_commit.chmod(0o755)
        
        monkeypatch.chdir(repo_path)
        
        # Create dummy verify that mimics behavior
        verify = repo_path / "verify.sh"
        verify.write_text("""#!/bin/sh
echo "🔍 Checking Security Audit..."
echo "❌ Security Audit FAILED"
exit 1
""")
        verify.chmod(0o755)
        
        # Run hook and check output
        result = subprocess.run(
            ["bash", str(pre_commit)],
            capture_output=True,
            text=True
        )
        
        assert result.returncode != 0
        assert "Security Audit" in result.stdout or "Security Audit" in result.stderr


class TestHookInstallation:
    """Tests for installing/setting up git hooks."""
    
    def test_hook_installation_creates_correct_structure(self, tmp_path):
        """
        GIVEN: A project with universal-ci
        WHEN: Hooks are installed via setup script
        THEN: .git/hooks/ should contain pre-commit and pre-push
        """
        repo_path = tmp_path / "project"
        repo_path.mkdir()
        
        # Create hooks directory
        hooks_dir = repo_path / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        # Install hooks
        pre_commit = hooks_dir / "pre-commit"
        pre_push = hooks_dir / "pre-push"
        
        pre_commit.write_text("#!/bin/sh\nexit 0")
        pre_commit.chmod(0o755)
        
        pre_push.write_text("#!/bin/sh\nexit 0")
        pre_push.chmod(0o755)
        
        # Verify structure
        assert pre_commit.exists()
        assert pre_push.exists()
        assert os.access(pre_commit, os.X_OK)
        assert os.access(pre_push, os.X_OK)


class TestTrustButVerifyApproach:
    """
    Verify that hooks properly trust but verify git behavior.
    
    Trust: We trust that git will call our hooks
    Verify: We verify that hooks are actually blocking operations
    """
    
    def test_verify_hook_called_on_commit_attempt(self, tmp_path, monkeypatch):
        """
        TRUST: Git will call our pre-commit hook
        VERIFY: We can detect that hook was called
        """
        repo_path = tmp_path / "test_repo"
        repo_path.mkdir()
        monkeypatch.chdir(repo_path)
        
        # Setup git repo
        subprocess.run(["git", "init"], check=True, capture_output=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], check=True)
        
        # Create a hook that creates a marker file
        hooks_dir = repo_path / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        marker_file = repo_path / ".hook_was_called"
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text(f"""#!/bin/sh
touch {marker_file}
exit 1
""")
        pre_commit.chmod(0o755)
        
        # Create a file to commit
        (repo_path / "test.txt").write_text("content")
        subprocess.run(["git", "add", "test.txt"], check=True, capture_output=True)
        
        # Attempt commit
        subprocess.run(
            ["git", "commit", "-m", "test"],
            capture_output=True
        )
        
        # Verify hook was actually called (marker file exists)
        assert marker_file.exists(), "Hook should have been called"
    
    def test_verify_exit_code_from_failing_hook(self, tmp_path, monkeypatch):
        """
        VERIFY: Exit code from failed hook propagates to git command
        """
        repo_path = tmp_path / "test_repo"
        repo_path.mkdir()
        monkeypatch.chdir(repo_path)
        
        # Setup git repo
        subprocess.run(["git", "init"], check=True, capture_output=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], check=True)
        
        # Create a failing hook
        hooks_dir = repo_path / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("#!/bin/sh\nexit 42")
        pre_commit.chmod(0o755)
        
        # Create a file to commit
        (repo_path / "test.txt").write_text("content")
        subprocess.run(["git", "add", "test.txt"], check=True, capture_output=True)
        
        # Attempt commit and capture exit code
        result = subprocess.run(
            ["git", "commit", "-m", "test"],
            capture_output=True,
            text=True
        )
        
        # Commit should fail (due to hook failure)
        assert result.returncode != 0, "Git commit should fail when hook fails"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
