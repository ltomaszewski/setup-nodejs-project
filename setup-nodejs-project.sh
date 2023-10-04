#!/bin/bash

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Please install it before running this script."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "npm is not installed. Please install it before running this script."
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install it before running this script."
    exit 1
fi

# Check if TypeScript is installed
if ! npm list -g typescript &> /dev/null; then
    echo "Installing TypeScript globally..."
    npm install -g typescript
fi

# Check if a project name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

# Extract the project name from the argument
project_name="$1"

# Create the project directory
echo "Creating project directory: $project_name..."
mkdir -p "$project_name"

# Change to the project directory
cd "$project_name"

# Initialize a new Node.js project with TypeScript
echo "Initializing a new Node.js project with TypeScript..."
npm init -y
tsc --init --target ESNext --module CommonJS --outDir ./dist --rootDir ./src --esModuleInterop --resolveJsonModule

# Create the tsconfig.json file
echo "Creating tsconfig.json file..."
cat <<EOL > tsconfig.json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "CommonJS",
    "outDir": "./dist",
    "rootDir": "./src",
    "esModuleInterop": true,
    "sourceMap": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "allowJs": true
  }
}
EOL

# Create the directory structure (same as before)
echo "Creating directory structure..."
mkdir -p .vscode
mkdir -p src/application/dtos
mkdir -p src/application/helpers
mkdir -p src/application/interfaces
mkdir -p src/application/services
mkdir -p src/config
mkdir -p src/domain/entities
mkdir -p src/error-handling
mkdir -p src/infrastructure/repositories
mkdir -p src/interfaces/controllers
mkdir -p src/interfaces/middlewares
mkdir -p src/interfaces/routes

echo "Creating index.ts file..."
cat <<EOL > src/index.ts
console.log("Hello, World!");
EOL

# Create Constants.ts file
echo "Creating Constants.ts file..."
cat <<EOL > src/application/Constants.ts
export const API_BASE_URL: string = "https://api.example.com";
export const MAX_RETRIES: number = 3;
// Add more constants as needed
EOL

# Create tasks.json file
echo "Creating tasks.json file..."
cat <<EOL > .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "type": "typescript",
            "tsconfig": "tsconfig.json",
            "option": "watch",
            "problemMatcher": [
                "\$tsc-watch"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "label": "tsc: watch - tsconfig.json"
        }
    ]
}
EOL

# Create launch.json file
echo "Creating launch.json file..."
cat <<EOL > .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "launch",
            "name": "Launch Program",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "program": "\${workspaceFolder}/dist/index.js",
            "args": [],
            "outFiles": [
                "\${workspaceFolder}/**/*.js"
            ]
        }
    ]
}
EOL

# Ask the user if RethinkDB should be installed
read -p "Do you want to install RethinkDB for this project? (y/n): " install_rethinkdb

if [ "$install_rethinkdb" == "y" ]; then
    # Install RethinkDB and TypeScript modules
    echo "Installing RethinkDB and TypeScript modules..."
    npm install rethinkdb @types/rethinkdb
    echo "RethinkDB and TypeScript modules installed successfully."
else
    echo "Skipping RethinkDB and TypeScript installation."
fi

# Create a .gitignore file
echo "Creating .gitignore file..."
cat <<EOL > .gitignore
# Node.js
node_modules/
dist/
.env

# Editor
.vscode/
.idea/

# OS generated files
.DS_Store
Thumbs.db

# Logs
*.log
logs/
EOL

# Initialize a Git repository
echo "Initializing Git repository..."
git init

# Display completion message
echo "Project setup complete. You can start working on your Node.js project with TypeScript in the '$project_name' directory."

