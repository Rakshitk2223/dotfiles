## Complete Dotfiles Migration Plan (Omarchy-Style)

Overview
This plan will transform your dotfiles from a personal setup to a production-ready, Omarchy-inspired system that:

- Never overwrites user customizations
- Uses migrations for breaking changes
- Provides hooks for user extensions
- Tracks installation state
- Has modular, testable components
  Total Timeline: 2-3 weeks (working a few hours per day)

---

Phase 0: Preparation & Safety (Day 1)
Goals:

- Create comprehensive backups
- Document current state
- Set up safe testing environment
- Create rollback plan
  Steps:
  0.1: System Snapshot
- Create Timeshift/Snapper snapshot of entire system
- Note the snapshot ID for rollback if needed
- Test that you can boot from snapshot
  0.2: Backup Current Dotfiles
- Copy entire dotfiles directory to backup location
- Export git repository to archive
- Save copy outside of home directory (external drive/cloud)
  0.3: Document Current State
- List all installed packages (pacman and yay)
- List all config files in use
- Screenshot current desktop setup
- Test that everything works (waybar, hyprland, ghostty, etc.)
- Document any custom modifications you've made
  0.4: Create Development Branch
- Create new git branch for migration work
- This keeps master branch untouched
- Can compare changes easily
- Easy rollback if needed
  0.5: Set Up Testing Environment
- Consider setting up VM with Arch for testing
- Or create separate user account for testing
- This lets you test changes without breaking main system

---

Phase 1: Repository Restructure (Day 2-3)
Goals:

- Reorganize files into Omarchy-style structure
- Separate defaults from user configs
- Create proper directory hierarchy
- Don't change any functionality yet
  Steps:
  1.1: Create New Directory Structure
- Create bin/ directory for management scripts
- Create default/ directory for shell defaults
- Create migrations/ directory (empty for now)
- Create themes/ directory for theme system
- Keep existing .config/, scripts/, Wallpapers/ as-is initially
  1.2: Move Shell Configuration Files
- Extract shell-specific parts from .zshrc into default/zsh/shell
- Extract aliases into default/zsh/aliases
- Extract functions into default/zsh/functions
- Keep .zshrc as a thin wrapper that sources these files
- Don't change behavior, just reorganize
  1.3: Reorganize Scripts
- Move utility scripts from .local/bin/scripts/ to bin/
- Rename them with dotfiles- prefix (e.g., dotfiles-screenshot)
- Keep functionality identical
- Update paths in config files that reference them
  1.4: Create Version File
- Add version file with current version (e.g., 1.0.0)
- Create CHANGELOG.md documenting current features
- This becomes baseline for future changes
  1.5: Test Restructure
- Install restructured dotfiles in test environment
- Verify all scripts still work
- Check that configs load properly
- Fix any broken paths

---

Phase 2: Create State Tracking System (Day 4-5)
Goals:

- Implement state management
- Track what's installed
- Track completed migrations
- Provide foundation for migration system
  Steps:
  2.1: Design State Directory Structure
- Decide on state directory location (~/.local/state/dotfiles/)
- Plan subdirectories: migrations/, migrations/skipped/, general state files
- Design state file naming convention
  2.2: Create State Management Script
- Create bin/dotfiles-state script
- Implement set, clear, and check operations
- Simple file-based state tracking
- Document state API for other scripts
  2.3: Track Installation State
- Create marker file when dotfiles are installed
- Track installed version
- Track which components are installed
- Track user choices (hardware-specific packages, etc.)
  2.4: Test State System
- Test setting and clearing states
- Verify state persists across sessions
- Check that state directory is created properly
- Document how to use state system

---

Phase 3: Implement Migration System (Day 6-7)
Goals:

- Create migration framework
- Handle one-time setup tasks
- Support skipping failed migrations
- Never run migrations twice
  Steps:
  3.1: Create Migration Runner Script
- Create bin/dotfiles-migrate script
- Scan migrations/ directory for .sh files
- Check state directory for completed migrations
- Run only new migrations in timestamp order
  3.2: Add Migration Safety Features
- Add error handling for failed migrations
- Prompt user to skip or abort on failure
- Track skipped migrations separately
- Log migration output for debugging
  3.3: Create Example Migrations
- Write migration template with comments
- Create sample migration for testing
- Document migration best practices
- Explain migration naming convention (Unix timestamp)
  3.4: Integrate into Update Process
- Add migration step to update script
- Show user which migrations will run
- Ask for confirmation before running
- Report migration results
  3.5: Test Migration System
- Create test migration that adds a file
- Run migration, verify it completes
- Run again, verify it skips
- Test skip functionality with failing migration

---

Phase 4: Build Hook System (Day 8)
Goals:

- Allow user customizations without forking
- Provide extension points
- Call hooks at appropriate times
- Keep hooks optional
  Steps:
  4.1: Create Hook Runner Script
- Create bin/dotfiles-hook script
- Check for hook file in user's config
- Execute hook if exists, skip silently if not
- Pass arguments to hook scripts
  4.2: Define Hook Points
- Identify where hooks should be called
  - post-update: After system update
  - theme-set: After theme change
  - font-set: After font change
  - post-install: After initial install
- Document each hook's purpose and arguments
  4.3: Create Hook Templates
- Create sample hooks in config/dotfiles/hooks/
- Add .sample extension so they're not executed
- Include detailed comments explaining usage
- Provide useful examples
  4.4: Integrate Hooks into Scripts
- Add hook calls to update script
- Add hook calls to theme script
- Add hook calls to install script
- Make sure hooks never break the process
  4.5: Test Hook System
- Create test hook that writes to file
- Run update process, verify hook executes
- Remove hook, verify process still works
- Test hook with failing script

---

Phase 5: Implement Config Management (Day 9-11)
Goals:

- Separate distributed configs from user configs
- Support config updates without losing customizations
- Provide backup system
- Show diffs when configs change
  Steps:
  5.1: Create Config Layering System
- Split Hyprland config into core/ (distributed) and local/ (user)
- Core contains: appearance, keybinds, programs, autostart
- Local contains: user overrides, custom settings
- Main config sources both layers
  5.2: Update Main Configs
- Modify hyprland.conf to source core files first
- Then source local files (which override core)
- Add comments explaining system
- Ensure local directory exists
  5.3: Create Config Refresh Script
- Create bin/dotfiles-refresh-config script
- Backs up user's current config with timestamp
- Copies new default from repository
- Shows diff if changes exist
- Only keeps backup if different
  5.4: Migrate Other Configs
- Apply layering to Waybar config
- Apply to Ghostty config
- Apply to other major configs
- Leave simpler configs as-is
  5.5: Test Config System
- Make change to core config, refresh
- Verify backup is created
- Make change to local config
- Verify local change survives core update

---

Phase 6: Build Update System (Day 12-14)
Goals:

- Create safe, reliable update process
- Show changelog before updating
- Create snapshots before major changes
- Run migrations automatically
- Call user hooks
  Steps:
  6.1: Create Update Confirmation Script
- Create bin/dotfiles-update-confirm script
- Show current version and new version
- Display relevant changelog entries
- Ask user to confirm update
- Allow cancellation
  6.2: Create Git Update Script
- Create bin/dotfiles-update-git script
- Pull latest from GitHub
- Handle merge conflicts gracefully
- Stash local changes if needed
- Report what changed
  6.3: Create Package Update Script
- Create bin/dotfiles-update-packages script
- Sync package lists with repo
- Install missing packages
- Skip already-installed packages
- Handle failures gracefully
  6.4: Create Main Update Script
- Create bin/dotfiles-update script
- Orchestrates entire update process:
  1. Show confirmation dialog
  2. Create system snapshot
  3. Update git repository
  4. Update system packages
  5. Run migrations
  6. Call post-update hook
  7. Suggest restart if needed
     6.5: Add Update Safety Features
- Error trapping and helpful messages
- Rollback instructions on failure
- State tracking of update progress
- Update available notification system
  6.6: Test Complete Update Flow
- Test update with no changes
- Test update with package changes
- Test update with config changes
- Test update with migrations
- Test failed update and recovery

---

Phase 7: Improve Installation System (Day 15-16)
Goals:

- Modular installation process
- Better error handling
- Progress indication
- Component selection
  Steps:
  7.1: Reorganize Install Scripts
- Split install.sh into logical sections
- Create scripts/install/preflight.sh for checks
- Create scripts/install/packages.sh for package installation
- Create scripts/install/config.sh for config deployment
- Create scripts/install/post-install.sh for finalization
  7.2: Add Installation Helpers
- Create scripts/helpers/logging.sh for consistent output
- Create scripts/helpers/errors.sh for error handling
- Create scripts/helpers/presentation.sh for UI elements
- Make functions reusable across scripts
  7.3: Improve Package Installation
- Check if package already installed before attempting
- Better error messages for failed installs
- Continue on non-critical package failures
- Log all installations
  7.4: Add Hardware Detection
- Auto-detect NVIDIA GPU
- Auto-detect ASUS laptop
- Auto-suggest relevant packages
- Still allow manual override
  7.5: Create Boot Script
- Create one-line web installer (boot.sh)
- Support custom repo/branch
- Clone to correct location
- Run installation script
  7.6: Test Installation
- Test fresh install in VM
- Test with different hardware configs
- Test with different package selections
- Verify all configs deploy correctly

---

Phase 8: Add Theme System (Day 17-18)
Goals:

- Unified theme management
- Easy theme switching
- Theme installation from repo
- Hooks for theme changes
  Steps:
  8.1: Create Theme Directory Structure
- Organize themes/ directory
- Each theme has subdirectory with all assets
- Include: hyprland, waybar, ghostty, colors, wallpapers
- Add preview.png for each theme
  8.2: Create Theme Scripts
- Create bin/dotfiles-theme-list to show available themes
- Create bin/dotfiles-theme-current to show active theme
- Create bin/dotfiles-theme-set to apply theme
- Create bin/dotfiles-theme-install to add new themes
- Create bin/dotfiles-theme-remove to remove themes
  8.3: Implement Theme Application
- Copy theme files to appropriate locations
- Update symlinks or configs
- Restart affected services
- Call theme-set hook
  8.4: Add Current Theme Tracking
- Track active theme in state
- Create symlink to current theme
- Allow easy theme switching
  8.5: Test Theme System
- Switch between included themes
- Install theme from external repo
- Verify all components change
- Test theme hook functionality

---

Phase 9: Documentation (Day 19-20)
Goals:

- Comprehensive README
- User guides
- Developer documentation
- Migration guide for existing users
  Steps:
  9.1: Update README
- Clear project description
- Feature list
- Quick start installation
- Screenshots/demo
- Link to detailed docs
  9.2: Write User Documentation
- Installation guide
- Update guide
- Customization guide (how to use hooks)
- Theme guide
- Troubleshooting guide
  9.3: Write Developer Documentation
- Architecture overview
- How to add migrations
- How to add new features
- Testing guidelines
- Contributing guidelines
  9.4: Create Migration Guide
- Guide for users upgrading from old system
- Explain new features
- Show how to preserve customizations
- Common migration issues
  9.5: Add Examples
- Example hooks
- Example migrations
- Example theme
- Example customizations

---

Phase 10: Testing & Validation (Day 21)
Goals:

- Comprehensive testing
- Fix any remaining issues
- Validate all features work
- Prepare for release
  Steps:
  10.1: Fresh Install Testing
- Test complete install in clean VM
- Verify all packages install
- Verify all configs deploy
- Test all included tools work
  10.2: Update Testing
- Install old version
- Make user customizations
- Update to new version
- Verify customizations preserved
  10.3: Migration Testing
- Test each migration individually
- Test migration failure handling
- Test skip functionality
- Verify state tracking works
  10.4: Hook Testing
- Test all hook points
- Test with and without hooks
- Test failing hooks
- Verify hooks receive correct arguments
  10.5: Theme Testing
- Test theme switching
- Test theme installation
- Test theme removal
- Verify all components update
  10.6: Edge Case Testing
- Test with partial installation
- Test with missing dependencies
- Test with conflicting configs
- Test recovery from failures

---

Phase 11: Gradual Rollout (Day 22-25)
Goals:

- Safe deployment
- Gather feedback
- Fix issues before wide release
- Document common problems
  Steps:
  11.1: Deploy to Your Main System
- Use your own system as first production test
- Document any issues
- Fix problems immediately
- Live with it for few days
  11.2: Beta Testing with Close Users
- Share with 2-3 trusted users
- Provide direct support
- Collect detailed feedback
- Fix reported issues
  11.3: Create Release Candidate
- Tag version as RC1
- Write release notes
- Create installation video
- Prepare announcement
  11.4: Limited Public Release
- Share on personal social media
- Post in small communities
- Monitor for issues
- Provide quick support
  11.5: Document Common Issues
- Create FAQ from beta feedback
- Add troubleshooting steps
- Update documentation
- Create issue templates

---

Phase 12: Public Release & Maintenance (Day 26+)
Goals:

- Official release
- Community building
- Ongoing maintenance
- Future improvements
  Steps:
  12.1: Official Release
- Merge to master branch
- Tag stable version (v1.0.0)
- Publish detailed release notes
- Announce on Reddit, Discord, etc.
  12.2: Set Up Community
- Create Discord server or discussion forum
- Set up GitHub Discussions
- Create contribution guidelines
- Establish issue triage process
  12.3: Create Release Checklist
- Document release process
- Automated version bumping
- Changelog generation
- Testing requirements
  12.4: Plan Future Improvements
- Collect feature requests
- Prioritize enhancements
- Plan next version
- Maintain roadmap

---

Rollback Plan (If Something Goes Wrong)
At Any Point:
Option 1: Git Rollback

- Checkout previous commit
- Re-run installation
- Your system returns to working state
  Option 2: Backup Restore
- Restore from backup directory
- Copy back config files
- Reinstall from backup
  Option 3: System Snapshot
- Boot from Timeshift snapshot
- System returns to pre-migration state
- Can extract individual files if needed
  Option 4: Hybrid Approach
- Keep old dotfiles directory
- Run old installation script
- Resume old system while fixing new one

---

Success Criteria
After Each Phase:

- All tests pass
- Documentation updated
- No functionality lost
- System remains stable
  Final Success Metrics:
- Fresh installation works perfectly
- Update preserves user customizations
- Migrations run smoothly
- Hooks function correctly
- Themes switch seamlessly
- Documentation is clear and complete
- 3-5 users successfully install and use

---

Risk Mitigation
Key Risks:
Risk 1: Breaking Current System

- Mitigation: Work in dev branch, test in VM first
- Fallback: Snapshots and backups at every step
  Risk 2: Losing User Customizations
- Mitigation: Config layering system preserves overrides
- Fallback: Detailed backup before migration
  Risk 3: Migration Failures
- Mitigation: Migrations can be skipped, state tracked
- Fallback: Migrations are optional, system works without
  Risk 4: Complex Update Process
- Mitigation: Extensive testing, clear error messages
- Fallback: Simple manual update instructions
  Risk 5: Incomplete Testing
- Mitigation: Multi-phase testing plan
- Fallback: Limited beta release before public

---

Timeline Summary
| Phase | Days | Milestone |
|-------|------|-----------|
| 0: Preparation | 1 | Backups complete, dev branch created |
| 1: Restructure | 2-3 | New directory structure working |
| 2: State System | 2 | State tracking functional |
| 3: Migrations | 2 | Migration system tested |
| 4: Hooks | 1 | Hook system integrated |
| 5: Config Mgmt | 3 | Config layering deployed |
| 6: Updates | 3 | Update system complete |
| 7: Install | 2 | Installation improved |
| 8: Themes | 2 | Theme system working |
| 9: Docs | 2 | Documentation complete |
| 10: Testing | 1 | All tests passing |
| 11: Rollout | 4 | Beta feedback incorporated |
| 12: Release | 1+ | Public release, maintenance |
Total: 21-25 days of focused work

---

This plan ensures you never break your system, can rollback at any time, and end up with a production-ready dotfiles system that others can safely use and customize.
