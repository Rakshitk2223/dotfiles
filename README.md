## Personal dotfiles configuration scripts

### Installation

Steps : 

1.  **Clone the repository recursively** into `~/.local/bin/dotfiles`:

    ```bash
    git clone https://github.com/mohak34/dotfiles.git ~/.local/bin/dotfiles
    ```

2.  **Navigate into the dotfiles directory**:

    ```bash
    cd ~/.local/bin/dotfiles
    ```

3.  **Make the installation script executable**:

    ```bash
    chmod +x install.sh
    ```

4.  **Run the installation script**:
    ```bash
    ./install.sh
    ```

### Update

To update to the latest configuration and packages:

```bash
./update.sh [--dry-run] [--force] [--backup-changed]
```

- --dry-run: show what would change without applying
- --force: overwrite locally changed files
- --backup-changed: back up files before overwriting
