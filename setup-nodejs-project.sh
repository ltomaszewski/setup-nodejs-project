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
mkdir -p src/application/entities
mkdir -p src/application/dtos
mkdir -p src/application/helpers
mkdir -p src/application/interfaces
mkdir -p src/application/services
mkdir -p src/application/repositories
mkdir -p src/config
mkdir -p src/error-handling
mkdir -p src/interfaces/controllers
mkdir -p src/interfaces/middlewares
mkdir -p src/interfaces/routes

# Create Constants.ts file
echo "Creating Constants.ts file..."
cat <<EOL > src/config/Constants.ts
// Enumeration representing different environment modes: Development and Production
export enum Env {
    Dev, // Development environment
    Prod // Production environment
}

// Base URL for API endpoints
export const API_BASE_URL: string = "https://api.example.com";

// Maximum number of retries for API requests
export const MAX_RETRIES: number = 3;
EOL

# Create CLIConfiguration.ts file
echo "Creating CLIConfiguration.ts file..."
cat <<EOL > src/config/CLIConfiguration.ts
// Importing the Env enum from the Constants module
import { Env } from "./Constants";

// Class representing CLI configuration
export class CLIConfiguration {
    readonly arg1: string; // Command line argument 1
    readonly env: Env; // Environment mode (Development or Production)

    // Private constructor to create an instance of CLIConfiguration
    private constructor(arg1: string, env: Env) {
        this.arg1 = arg1;
        this.env = env;
    }

    // Static method to create CLIConfiguration instance from command line arguments
    static fromCommandLineArguments(argv: string[]): CLIConfiguration {
        // Extracting value of arg1 from command line arguments
        const args = argv.find(arg => arg.startsWith('--arg1='))?.split('=')[1];
        
        // Checking if production mode flag is present in command line arguments
        const producationMode = argv.find(arg => arg.includes('--runmode=producation'));

        if (args) {
            // Determining the environment based on the presence of production mode flag
            const env = producationMode !== undefined ? Env.Prod : Env.Dev;
            // Creating and returning a new CLIConfiguration instance
            return new CLIConfiguration(args, env);
        } else {
            // Throwing an error if arg1 is not provided in the command line arguments
            throw new Error("Fatal error: Configuration argument not provided.");
        }
    }

    // Getter method to compute the database name based on the environment
    get databaseName(): string {
        if (this.env === Env.Dev) {
            // If in development environment, return the dev_sampleDB name
            return "dev_sampleDB".replace(".", "_");
        } else {
            // If in production environment, return the sampleDB name
            return "sampleDB".replace(".", "_");
        }
    }
}

EOL

# Create tasks.json file
echo "Creating vscode/tasks.json file..."
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
        "runOptions": {
            "runOn": "folderOpen",
        },
        "label": "tsc: watch - tsconfig.json"
    }
    ]
}
EOL

# Create launch.json file
echo "Creating vscode/launch.json file..."
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
            "program": "\${workspaceFolder}/dist/Index.js",
            "args": [
                "--arg1=TEST"
            ],
            "outFiles": [
                "\${workspaceFolder}/**/*.js"
            ],
            "resolveSourceMapLocations": [
                "${workspaceFolder}/**",
                "!**/node_modules/**"
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
mkdir -p src/application/repositories/DatabaseRepository
cat <<EOL > src/application/repositories/DatabaseRepository/DatabaseRepository.ts
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
    // forceDrop - Property to recreate database on every connection
    forceDrop: boolean

    constructor(host: string, port: number, forceDrop: boolean = false) {
        this.host = host;
        this.port = port;
        this.forceDrop = forceDrop
        this.conn = null
    }

    // connect - establishes a connection to the RethinkDB server
    async connect(databaseName: string) {
        this.conn = await r.connect({ host: this.host, port: this.port })
        const schema = new Schema(databaseName, this)
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
    async delete(databaseName: string, tableName: string, filter: any) {
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

# Create Schema.ts file with specified content
echo "Creating Schema.ts file..."
cat <<EOL > src/application/repositories/DatabaseRepository/Schema.ts
import * as r from 'rethinkdb';
import { DatabaseRepository } from './DatabaseRepository';
import { SampleEntity } from '../../../application/entities/SampleEntity';

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

# Create EntityFactory.ts file with specified content
echo "Creating EntityFactory.ts file..."
cat <<EOL > src/application/entities/EntityFactory.ts
import { SampleEntity } from "./SampleEntity";

export class EntityFactory {
    static createSampleEntity(object: any): SampleEntity {
        return new SampleEntity(object.id, object.text)
    }
}
EOL

# Create SampleEntity.ts file with specified content
echo "Creating SampleEntity.ts file..."
cat <<EOL > src/application/entities/SampleEntity.ts
// SampleEntity - a sample entity class with a readonly property 'text'
export class SampleEntity {
    static Schema = {
        name: "SampleEntity",
        properties: {
            id: 'id',
            text: 'text'
        },
    };
    readonly id: number
    readonly text: string

    constructor(id: number, text: string) {
        this.id = id
        this.text = text
    }
}

EOL

# Create Repository.ts file with specified content
echo "Creating Repository.ts file..."
cat <<EOL > src/application/interfaces/Repository.ts
// Repository - Generic Repository type
export type Repository<T> = {
    insert(entity: T): void;
    getAll(): Promise<T[]>
    update(entity: T, newData: Partial<T>): void;
    delete(entity: T): void;
};
EOL

# Create SampleEntityRepository.ts file with specified content
echo "Creating SampleEntityRepository.ts file..."
cat <<EOL > src/application/repositories/SampleEntityRepository.ts
import { EntityFactory } from "../entities/EntityFactory";
import { SampleEntity } from "../entities/SampleEntity";
import { Repository } from "../interfaces/Repository";
import { DatabaseRepository } from "./DatabaseRepository/DatabaseRepository";

// SampleEntityRepository - Repository class for SampleEntity
export class SampleEntityRepository implements Repository<SampleEntity> {
    private databaseRepository: DatabaseRepository
    private databaseName: string

    constructor(databaseRepository: DatabaseRepository, databaseName: string) {
        this.databaseRepository = databaseRepository
        this.databaseName = databaseName
    }

    async insert(entity: SampleEntity) {
        await this.databaseRepository.insert(this.databaseName, SampleEntity.Schema.name, entity)
    }

    async getAll(): Promise<SampleEntity[]> {
        const result = (await this.databaseRepository.query(this.databaseName, SampleEntity.Schema.name, function (table) { return table }))
        const rawResult = await result.toArray()
        const sampleEntities = rawResult.map((object: any) => { return EntityFactory.createSampleEntity(object) })
        result.close()
        return sampleEntities
    }

    async update(entity: SampleEntity) {
        await this.databaseRepository.insert(this.databaseName, SampleEntity.Schema.name, entity)
    }

    async delete(entity: SampleEntity) {
        await this.databaseRepository.delete(this.databaseName, SampleEntity.Schema.name, { id: entity.id })
    }
}
EOL

# Append properties to Constants.ts file
echo "Appending properties to Constants.ts file..."
cat <<EOL >> src/config/Constants.ts
// DatabaseHost - the hostname of the RethinkDB server
export const DatabaseHost = '192.168.1.1';
// DatabasePort - the port number of the RethinkDB server
export const DatabasePort = 28015;
// DatabaseForceDrop - indicates whether the database should be forcefully dropped (true/false)
export const DatabaseForceDrop = false;
EOL

# Create Repository.ts file with specified content
echo "Creating Repository.ts file..."
cat <<EOL > src/application/interfaces/Repository.ts
// Repository - Generic Repository type
export type Repository<T> = {
    insert(entity: T): void;
    getAll(): Promise<T[]>
    update(entity: T, newData: Partial<T>): void;
    delete(entity: T): void;
};
EOL

# Create Index.ts file with specified content
echo "Creating Index.ts file..."
cat <<EOL > src/Index.ts
// Importing CLIConfiguration class for handling Command Line Interface (CLI) arguments
import { CLIConfiguration } from "./config/CLIConfiguration";

// Extracting command line arguments
const args = process.argv;

// Creating CLIConfiguration object from the extracted CLI arguments
export const configuration: CLIConfiguration = CLIConfiguration.fromCommandLineArguments(args);

// Logging the configuration details
console.log("Application started with configuration: " + configuration.arg1 + ", environment: " + configuration.env);

// Importing necessary modules and classes for database integration
import { DatabaseRepository } from "./application/repositories/DatabaseRepository/DatabaseRepository";
import { DatabaseHost, DatabasePort } from "./config/Constants";
import { SampleEntityRepository } from "./application/repositories/SampleEntityRepository";
import { SampleEntity } from "./application/entities/SampleEntity";

// Asynchronous function for database operations
(async () => {
    // Database connection details
    const databaseName = "TralalaTestowaBaza";

    // Creating DatabaseRepository instance for database connection
    const databaseRepository = new DatabaseRepository(DatabaseHost, DatabasePort, true);

    // Establishing connection to the specified database
    await databaseRepository.connect(databaseName);

    // Creating SampleEntityRepository instance for database operations
    const sampleEntityRepository = new SampleEntityRepository(databaseRepository, databaseName);

    // Creating sample entities for insertion
    const firstEntry = new SampleEntity(1, "jeden");
    const secondEntry = new SampleEntity(2, "dwa");

    // Inserting the first entity into the database
    await sampleEntityRepository.insert(firstEntry);

    // Retrieving all sample entities from the database for validation
    const allSampleEntities = await sampleEntityRepository.getAll();
    console.log("All sample entities after insertion: ", allSampleEntities);

    // Updating the first entity in the database
    const updatedFirstEntry = new SampleEntity(firstEntry.id, "Jeden after updated");
    await sampleEntityRepository.update(updatedFirstEntry);

    // Retrieving all sample entities after update for validation
    const allSampleEntitiesAfterUpdate = await sampleEntityRepository.getAll();
    console.log("All sample entities after update: ", allSampleEntitiesAfterUpdate);

    // Deleting the first entity from the database
    await sampleEntityRepository.delete(firstEntry);

    // Retrieving all sample entities after deletion for validation
    const allSampleEntitiesAfterDelete = await sampleEntityRepository.getAll();
    console.log("All sample entities after deletion: ", allSampleEntitiesAfterDelete);
})();
EOL

echo "RethinkDB and TypeScript modules installed. DatabaseRepository.ts created."
else
# Create Index.ts file with specified content
echo "Creating Index.ts file..."
cat <<EOL > src/Index.ts
// Importing CLIConfiguration class for handling Command Line Interface (CLI) arguments
import { CLIConfiguration } from "./config/CLIConfiguration";

// Extracting command line arguments
const args = process.argv;

// Creating CLIConfiguration object from the extracted CLI arguments
export const configuration: CLIConfiguration = CLIConfiguration.fromCommandLineArguments(args);

// Logging the configuration details
console.log("Application started with configuration: " + configuration.arg1 + ", environment: " + configuration.env);
EOL

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

