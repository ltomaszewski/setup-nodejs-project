# Node.js TypeScript Project Setup Script

This Bash script automates the setup process for a new Node.js project with TypeScript. It checks for dependencies, initializes the project, and provides an organized directory structure. Optionally, it integrates RethinkDB into the project.

## Prerequisites

- [Node.js](https://nodejs.org/) installed
- [npm](https://www.npmjs.com/) (Node.js package manager) installed
- [Git](https://git-scm.com/) installed (optional, but recommended)
- [TypeScript](https://www.typescriptlang.org/) installed globally (automatically installed if missing)
- (Optional) [RethinkDB](https://rethinkdb.com/) installed (if you choose to install it)

## Usage

1. **Clone or Download the Script:**
   - Clone this repository or download the `setup-nodejs-project.sh` script.

2. **Navigate to the Script Directory:**
   - Open your terminal and navigate to the directory where you saved the script.

3. **Run the Script:**
   ```bash
   ./setup-nodejs-project.sh <project-name>

## Script Features

- Checks for Node.js, npm, and Git installations.
- Installs TypeScript globally if not already installed.
- Initializes a new Node.js project with TypeScript configuration.
- Organizes the project with a predefined directory structure.
- (Optional) Asks if you want to install RethinkDB and integrates it into the project.
