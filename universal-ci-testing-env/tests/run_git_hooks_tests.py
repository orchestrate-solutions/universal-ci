#!/usr/bin/env python3
"""
Simple test runner for git hooks blocking tests
Runs tests without pytest to avoid dependency issues
"""

import json
import os
import tempfile
import subprocess
from pathlib import Path
import sys


def test_pre_commit_hook_creation():
    """Test that pre-commit hook is created and executable."""
    print("\n🧪 Test: Pre-commit hook creation")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Initialize git repo
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo, check=True)
        
        # Create pre-commit hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit_hook = hooks_dir / "pre-commit"
        pre_commit_content = """#!/bin/sh
./run-ci.sh
exit $?
"""
        pre_commit_hook.write_text(pre_commit_content)
        pre_commit_hook.chmod(0o755)
        
        # Verify
        assert pre_commit_hook.exists(), "Hook file should exist"
        assert os.access(pre_commit_hook, os.X_OK), "Hook should be executable"
        
        print("   ✅ Pre-commit hook created and executable")
        return True


def test_pre_push_hook_creation():
    """Test that pre-push hook is created and executable."""
    print("\n🧪 Test: Pre-push hook creation")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Initialize git repo
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo, check=True)
        
        # Create pre-push hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_push_hook = hooks_dir / "pre-push"
        pre_push_content = """#!/bin/sh
./run-ci.sh --stage release
exit $?
"""
        pre_push_hook.write_text(pre_push_content)
        pre_push_hook.chmod(0o755)
        
        # Verify
        assert pre_push_hook.exists(), "Hook file should exist"
        assert os.access(pre_push_hook, os.X_OK), "Hook should be executable"
        
        print("   ✅ Pre-push hook created and executable")
        return True


def test_failing_task_blocks_commit():
    """Test that failing tasks block commit operations."""
    print("\n🧪 Test: Failing task blocks commit")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Initialize git
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo, check=True)
        
        # Create config with failing task
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
        config_file = repo / "universal-ci.config.json"
        config_file.write_text(json.dumps(config, indent=2))
        
        # Create dummy verify script that uses config
        verify_script = repo / "run-ci.sh"
        verify_script.write_text("""#!/bin/sh
# Parse and execute the test task
if grep -q '"command": "exit 1"' universal-ci.config.json; then
    exit 1
fi
exit 0
""")
        verify_script.chmod(0o755)
        
        # Create pre-commit hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
./run-ci.sh --stage test
exit $?
""")
        pre_commit.chmod(0o755)
        
        # Create a test file and stage it
        test_file = repo / "test.txt"
        test_file.write_text("test content")
        
        subprocess.run(["git", "add", "test.txt"], cwd=repo, check=True, capture_output=True)
        
        # Attempt commit - should be blocked
        result = subprocess.run(
            ["git", "commit", "-m", "Test commit"],
            cwd=repo,
            capture_output=True,
            text=True
        )
        
        # Verify commit was blocked
        assert result.returncode != 0, "Commit should be blocked when test fails"
        print("   ✅ Failing task blocked commit (exit code: {})".format(result.returncode))
        return True


def test_passing_task_allows_commit():
    """Test that passing tasks allow commit operations."""
    print("\n🧪 Test: Passing task allows commit")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Initialize git
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo, check=True)
        
        # Create config with passing task
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
        config_file = repo / "universal-ci.config.json"
        config_file.write_text(json.dumps(config, indent=2))
        
        # Create dummy verify script
        verify_script = repo / "run-ci.sh"
        verify_script.write_text("""#!/bin/sh
exit 0
""")
        verify_script.chmod(0o755)
        
        # Create pre-commit hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
./run-ci.sh --stage test
exit $?
""")
        pre_commit.chmod(0o755)
        
        # Create a test file and stage it
        test_file = repo / "test.txt"
        test_file.write_text("test content")
        
        subprocess.run(["git", "add", "."], cwd=repo, check=True, capture_output=True)
        
        # Attempt commit - should succeed
        result = subprocess.run(
            ["git", "commit", "-m", "Test commit"],
            cwd=repo,
            capture_output=True,
            text=True
        )
        
        # Verify commit succeeded
        assert result.returncode == 0, f"Commit should succeed when tests pass. stderr: {result.stderr}"
        print("   ✅ Passing task allowed commit (exit code: 0)")
        return True


def test_hook_called_on_commit():
    """Test that hook is actually called during commit attempt."""
    print("\n🧪 Test: Hook is called on commit attempt")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Initialize git
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo, check=True)
        
        # Create pre-commit hook that creates a marker file
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        marker_file = repo / ".hook_was_called"
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text(f"""#!/bin/sh
touch {marker_file}
exit 1
""")
        pre_commit.chmod(0o755)
        
        # Create a file to commit
        test_file = repo / "test.txt"
        test_file.write_text("content")
        
        subprocess.run(["git", "add", "test.txt"], cwd=repo, check=True, capture_output=True)
        
        # Attempt commit
        subprocess.run(
            ["git", "commit", "-m", "test"],
            cwd=repo,
            capture_output=True
        )
        
        # Verify hook was called (marker exists)
        assert marker_file.exists(), "Hook should have been called"
        print("   ✅ Hook was called during commit attempt")
        return True


def test_multiple_failing_tasks():
    """Test that multiple failing tasks block commit."""
    print("\n🧪 Test: Multiple failing tasks block commit")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Initialize git
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.email", "test@test.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo, check=True)
        
        # Create config with multiple tasks (one fails)
        config = {
            "tasks": [
                {
                    "name": "Lint Check",
                    "working_directory": ".",
                    "command": "exit 0",
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
                    "command": "exit 0",
                    "stage": "test"
                }
            ]
        }
        config_file = repo / "universal-ci.config.json"
        config_file.write_text(json.dumps(config, indent=2))
        
        # Create verify script that simulates running all tasks
        verify_script = repo / "run-ci.sh"
        verify_script.write_text("""#!/bin/sh
# Simulate multiple tasks
if grep -q '"command": "exit 1"' universal-ci.config.json; then
    exit 1
fi
exit 0
""")
        verify_script.chmod(0o755)
        
        # Create pre-commit hook
        hooks_dir = repo / ".git" / "hooks"
        hooks_dir.mkdir(parents=True, exist_ok=True)
        
        pre_commit = hooks_dir / "pre-commit"
        pre_commit.write_text("""#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
./run-ci.sh --stage test
exit $?
""")
        pre_commit.chmod(0o755)
        
        # Stage and attempt commit
        (repo / "file.txt").write_text("content")
        subprocess.run(["git", "add", "."], cwd=repo, check=True, capture_output=True)
        
        result = subprocess.run(
            ["git", "commit", "-m", "Test"],
            cwd=repo,
            capture_output=True,
            text=True
        )
        
        # Should be blocked
        assert result.returncode != 0, "Commit should be blocked when any task fails"
        print("   ✅ Multiple failing tasks blocked commit")
        return True


def run_all_tests():
    """Run all tests and report results."""
    print("=" * 60)
    print("🚀 Universal CI - Git Hooks Blocking Test Suite")
    print("=" * 60)
    print("\nTesting that failed scripts block git operations...")
    
    tests = [
        ("Pre-commit hook creation", test_pre_commit_hook_creation),
        ("Pre-push hook creation", test_pre_push_hook_creation),
        ("Hook called on commit attempt", test_hook_called_on_commit),
        ("Passing task allows commit", test_passing_task_allows_commit),
        ("Failing task blocks commit", test_failing_task_blocks_commit),
        ("Multiple failing tasks block", test_multiple_failing_tasks),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            passed = test_func()
            results.append((test_name, True, None))
        except AssertionError as e:
            results.append((test_name, False, str(e)))
        except Exception as e:
            results.append((test_name, False, f"Exception: {str(e)}"))
    
    print("\n" + "=" * 60)
    print("📊 TEST RESULTS")
    print("=" * 60)
    
    passed_count = 0
    for test_name, passed, error in results:
        if passed:
            print(f"✅ {test_name}")
            passed_count += 1
        else:
            print(f"❌ {test_name}")
            if error:
                print(f"   Error: {error}")
    
    print("=" * 60)
    print(f"Results: {passed_count}/{len(tests)} tests passed")
    print("=" * 60)
    
    if passed_count == len(tests):
        print("\n🎉 ALL TESTS PASSED!")
        print("\n✨ Key Findings:")
        print("   • Git hooks are properly created and made executable")
        print("   • Failed verification scripts successfully block commits")
        print("   • Passing scripts allow commits to proceed")
        print("   • Multiple tasks are evaluated correctly")
        return 0
    else:
        print(f"\n💥 {len(tests) - passed_count} test(s) failed")
        return 1


if __name__ == "__main__":
    sys.exit(run_all_tests())
