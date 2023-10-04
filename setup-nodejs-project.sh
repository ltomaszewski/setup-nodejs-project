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
# Create DatabaseRepository.ts file with specified content
echo "Creating DatabaseRepository.ts file..."
mkdir -p src/infrastructure/repositories/DatabaseRepository
cat <<EOL > src/infrastructure/repositories/DatabaseRepository/DatabaseRepository.ts
import * as r from 'rethinkdb';
import { Schema } from './Schema';

// DatabaseRepository - a repository for interacting with RethinkDB databases
export class DatabaseRepository {
    // host - the hostname of the RethinkDB server
    readonly host: string;
    // port - the port number of the RethinkDB server
    readonly port: number;
    // conn - the RethinkDB connection object (null until connected)
    private conn: r.Connection | null;
    // databaseName - database name
    readonly databaseName: string
    // forceDrop - Property to recreate database on every connection
    forceDrop: boolean

    constructor(databaseName: string, host: string, port: number, forceDrop: boolean = false) {
        this.databaseName = databaseName
        this.host = host;
        this.port = port;
        this.forceDrop = forceDrop
        this.conn = null
    }

    // connect - establishes a connection to the RethinkDB server
    async connect() {
        this.conn = await r.connect({ host: this.host, port: this.port })
        const schema = new Schema(this.databaseName, this)
        await schema.updateSchemaIfNeeded(this.forceDrop)
    }

    // closeConnection - closes the RethinkDB connection
    async closeConnection() {
        if (this.conn === null) {
            throw new Error('Connection is null')
        }
        await this.conn.close()
    }

    // createDatabaseIfNotExists - creates a new database if it does not already exist
    async createDatabaseIfNotExists(name: string) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        const dbList = await r.dbList().run(this.conn)
        if (dbList.includes(name)) {
            return
        }
        await r.dbCreate(name).run(this.conn)
    }

    // createTableIfNotExists - creates a new table if it does not already exist
    async createTableIfNotExists(databaseName: string, tableName: string) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        const tableList = await r.db(databaseName).tableList().run(this.conn)
        if (tableList.includes(tableName)) {
            return
        }
        await r.db(databaseName).tableCreate(tableName).run(this.conn);
    }

    // dropDatabaseIfExists - drops a database if it exists
    async dropDatabaseIfExists(name: string) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        const dbList = await r.dbList().run(this.conn);
        if (dbList.includes(name)) {
            await r.dbDrop(name).run(this.conn);
        }
    }

    // dropTableIfExists - drops a table if it exists
    async dropTableIfExists(databaseName: string, tableName: string) {
        if (this.conn === null) {
            throw new Error('Connection is null')
        }

        const dbList = await r.dbList().run(this.conn);
        if (!dbList.includes(databaseName)) {
            return
        }

        const tableList = await r.db(databaseName).tableList().run(this.conn)
        if (tableList.includes(tableName)) {
            await r.db(databaseName).tableDrop(tableName).run(this.conn)
        }
    }

    async createIndexIfNotExists(databaseName: string, tableName: string, indexName: string, indexFunction: string) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        const db = r.db(databaseName);
        const table = db.table(tableName);

        // Check if the index already exists
        const indexList = await table.indexList().run(this.conn);
        if (indexList.includes(indexName)) {
            return; // Index already exists, no need to create it
        }

        // Create the index
        await table.indexCreate(indexName, [r.row(indexFunction)]).run(this.conn);
        await table.indexWait(indexName).run(this.conn)
    }

    // insert - inserts an object into a table
    async insert<T>(databaseName: string, tableName: string, object: T) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        await r.db(databaseName).table(tableName).insert(object, { conflict: "replace" }).run(this.conn);
    }

    // update - updates an object in a table
    async update<T>(databaseName: string, tableName: string, filter: r.ExpressionFunction<boolean>, obj: Object, options?: r.UpdateOptions) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        await r
            .db(databaseName)
            .table(tableName)
            .filter(filter) // You can use filter criteria to identify the entry to update
            .update(obj, options) // Update the entry with the provided updates
            .run(this.conn);
    }

    // delete - delete an object in a table
    async delete(databaseName: string, tableName: string, filter: r.ExpressionFunction<boolean>) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        await r
            .db(databaseName)
            .table(tableName)
            .filter(filter) // You can use filter criteria to identify the entry to delete
            .delete() // Delete the matching entry
            .run(this.conn);
    }

    // query - executes a query on a table
    async query<T>(databaseName: string, tableName: string, query: (table: r.Table) => r.Sequence) {
        if (this.conn === null) {
            throw new Error('Connection is null');
        }

        const result = await query(r.db(databaseName).table(tableName)).run(this.conn)
        return result;
    }

    // changes - retrieves a list of changes made to a table
    async changes<T>(databaseName: string, tableName: string, callback: (change: T[]) => void) {
        if (this.conn !== null) {
            const changeCursor = await r
                .db(databaseName)
                .table(tableName)
                .changes()
                .run(this.conn);

            changeCursor.each((err, change) => {
                if (err) {
                    throw err;
                }
                callback(change);
            });
        } else {
            throw new Error('Connection is null');
        }
    }
}
EOL

# Create SampleEntity.ts file with specified content
echo "Creating SampleEntity.ts file..."
mkdir -p src/domain/entities
cat <<EOL > src/domain/entities/SampleEntity.ts
// SampleEntity - a sample entity class with a readonly property 'text'
export class SampleEntity {
    static Schema = {
        name: "SampleEntity",
        properties: {
            text: 'text',
        },
    };
    readonly text: string;
    
    constructor(text: string) {
        this.text = text;
    }
}

EOL

# Create Schema.ts file with specified content
echo "Creating Schema.ts file..."
mkdir -p src/infrastructure/repositories/DatabaseRepository
cat <<EOL > src/infrastructure/repositories/DatabaseRepository/Schema.ts
import * as r from 'rethinkdb';
import { DatabaseRepository } from './DatabaseRepository';
import { SampleEntity } from '../../../domain/entities/SampleEntity';

// Schema - responsible for database schema migration
export class Schema {
    databaseName: string
    private databaseRepository: DatabaseRepository
    
    constructor(databaseName: string, databaseRepository: DatabaseRepository) {
        this.databaseName = databaseName
        this.databaseRepository = databaseRepository
    }
    
    async updateSchemaIfNeeded(dropAllFirst: boolean = false) {
        if (dropAllFirst) {
            await this.databaseRepository.dropTableIfExists(this.databaseName, SampleEntity.Schema.name)
            await this.databaseRepository.dropDatabaseIfExists(this.databaseName)
        }
        
        await this.databaseRepository.createDatabaseIfNotExists(this.databaseName)
        await this.databaseRepository.createTableIfNotExists(this.databaseName, SampleEntity.Schema.name)
    }
}
EOL

# Append properties to Constants.ts file
echo "Appending properties to Constants.ts file..."
cat <<EOL >> src/application/Constants.ts
// DatabaseHost - the hostname of the RethinkDB server
export const DatabaseHost = '192.168.1.1';
// DatabasePort - the port number of the RethinkDB server
export const DatabasePort = 28015;
// DatabaseForceDrop - indicates whether the database should be forcefully dropped (true/false)
export const DatabaseForceDrop = false;
EOL

echo "RethinkDB and TypeScript modules installed. DatabaseRepository.ts created."
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

