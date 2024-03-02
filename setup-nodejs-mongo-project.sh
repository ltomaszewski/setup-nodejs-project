#!/bin/bash

# Check if MongoDB is installed
if ! command -v mongosh &> /dev/null; then
    echo "MongoDB is not installed. Please install it before running this script."
    exit 1
fi

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
npm i --save-dev @types/node
npm i --save dotenv
npm i --save-dev @types/dotenv

echo "Installing MongoDB and TypeScript modules..."
npm install mongodb

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

function getEnvVar(key: string): string {
    const value = process.env[key];
    if (value === undefined) {
        throw new Error('Environment variable \${key} is not set');
    }
    return value;
}

export interface ProcessEnv {
    MONGO_DB_URL: string;
    DEV_MONGO_DB_URL: string;
}

export const dotEnv: ProcessEnv = {
    MONGO_DB_URL: getEnvVar('MONGO_DB_URL'),
    DEV_MONGO_DB_URL: getEnvVar('DEV_MONGO_DB_URL')
};
EOL

# Setup MongoDB connection

# Function to generate a random password
generate_random_password() {
    head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9'
}

# Function to create a new user for the main database
read -p "Do you want to connect to a local MongoDB instance? (y/n): " local_instance

if [ "$local_instance" = "y" ]; then
    mongo_uri="localhost"
else
    read -p "Enter the remote MongoDB instance URI: " mongo_uri
fi

read -p "Enter the port for MongoDB server (default: 26967): " port
port=${port:-26967}

mongo_uri_without_prefix="$mongo_uri:$port"
mongo_uri="mongodb://$mongo_uri:$port"

echo "Connecting to MongoDB instance at $mongo_uri..."
mongosh "$mongo_uri" --eval "quit()"

# Create database and username
read -p "Enter the name of the database: " dbname
read -p "Enter the desired username for the database: " username

dev_dbname="dev_$dbname"
dev_username="dev_$username"
password=$(generate_random_password)
dev_password=$(generate_random_password)

# Create user for development database
echo "Creating user '$dev_username' with password '$dev_password' for development database '$dev_dbname'..."
mongosh "$mongo_uri"  <<EOF
use $dev_dbname
db.createUser({ user: "$dev_username", pwd: "$dev_password", roles: [{ role: "readWrite", db: "$dev_dbname" }] })
EOF

echo "User '$dev_username' created for development database '$dev_dbname'."

# Create user for main database
echo "Creating user '$username' with password '$password' for database '$dbname'..."
mongosh "$mongo_uri" <<EOF
use $dbname
db.createUser({ user: "$username", pwd: "$password", roles: [{ role: "readWrite", db: "$dbname" }] })
EOF

echo "User '$dev_username' created for development database '$dev_dbname'."

# Pring MongoDb connection URL
mongo_url="mongodb://$username:$password@$mongo_uri_without_prefix/$dbname?directConnection=true&serverSelectionTimeoutMS=2000"
dev_mongo_url="mongodb://$dev_username:$dev_password@$mongo_uri_without_prefix/$dev_dbname?directConnection=true&serverSelectionTimeoutMS=2000"

echo "MongoDB dev_connection URL: $mongo_url"
echo "MongoDB dev_connection URL: $dev_mongo_url"

# Create Constants.ts file
echo "Creating .env file..."
cat <<EOL > .env
MONGO_DB_URL=$mongo_url
DEV_MONGO_DB_URL=$dev_mongo_url
EOL

# Create CLIConfiguration.ts file
echo "Creating CLIConfiguration.ts file..."
cat <<EOL > src/config/CLIConfiguration.ts
// Importing the Env enum from the Constants module
import { Env } from "./Constants.js";

// Class representing CLI configuration
export class CLIConfiguration {
    readonly env: Env; // Environment mode (Development or Production)

    // Private constructor to create an instance of CLIConfiguration
    private constructor(env: Env) {
        this.env = env;
    }

    // Static method to create CLIConfiguration instance from command line arguments
    static fromCommandLineArguments(argv: string[]): CLIConfiguration {
        // Checking if production mode flag is present in command line arguments
        const producationMode = argv.find(arg => arg.includes('--runmode=producation'));
        const env = producationMode !== undefined ? Env.Prod : Env.Dev;
        // Creating and returning a new CLIConfiguration instance
        return new CLIConfiguration(env);
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
                // "--runmode=producation"
            ],
            "outFiles": [
                "\${workspaceFolder}/**/*.js"
            ],
            "resolveSourceMapLocations": [
                "\${workspaceFolder}/**",
                "!**/node_modules/**"
            ]
        }
    ]
}
EOL

# Create MongoRepository.ts file with specified content
echo "Creating MongoRepository.ts file..."
cat <<'EOL' > src/application/repositories/MongoRepository.ts
import { MongoClient, Collection, ObjectId, WithId } from 'mongodb';

interface BaseDocument {
    _id?: ObjectId;
}

export class MongoRepository<T extends BaseDocument> {
    private collection: Collection<T>;

    constructor(db: MongoClient, collectionName: string) {
        this.collection = db.db().collection<T>(collectionName);
    }

    async insert(item: Omit<T, '_id'>): Promise<WithId<T>> {
        const result = await this.collection.insertOne(item as any);
        return { ...item, _id: result.insertedId } as WithId<T>;
    }

    async findAll(): Promise<T[]> {
        const documents = await this.collection.find({}).toArray();
        return documents.map(doc => doc as T);
    }

    async findOne(id: ObjectId): Promise<T | null> {
        const document = await this.collection.findOne({ _id: id } as any);
        return document as T | null;
    }

    async find(query: Partial<T>): Promise<T[]> {
        const documents = await this.collection.find(query as any).toArray();
        return documents.map(doc => doc as T);
    }

    async watchInsertOrUpdate() {
        const watchStream = await this.collection.watch([{ $match: { operationType: 'insert' } }]);
        watchStream.on('change', (change) => {
            if (change.operationType === 'insert' || change.operationType === 'update') {
                console.log('A new or updated document:', change.fullDocument);
            }
        });
    }

    async findOneAndUpdate(id: ObjectId, item: Partial<T>): Promise<T | null> {
        const result = await this.collection.findOneAndUpdate(
            { _id: id as any },
            { $set: item },
            { returnDocument: 'after' }
        );
        if (!result) return null;
        return result as T;
    }

    async delete(id: string): Promise<void> {
        await this.collection.deleteOne({ _id: new ObjectId(id) } as any);
    }

    async deleteMany() {
        try {
            const result = await this.collection.deleteMany({});
            console.log(`Deleted ${result.deletedCount} document`);
        } catch (error) {
            console.error('Error deleting documents', error);
        } finally {
            console.log('Finished deleting documents');
        }
    }
}
EOL


# Create SampleEntityRepository.ts file with specified content
echo "Creating SampleEntityRepository.ts file..."
cat <<EOL > src/application/repositories/SampleEntityRepository.ts
import { MongoClient } from "mongodb";
import { SampleEntity } from "../entities/SampleEntity.js";
import { MongoRepository } from "./MongoRepository.js";

export class SampleEntityRepository extends MongoRepository<SampleEntity> {
    constructor(client: MongoClient) {
        super(client, SampleEntity.Schema.name);
    }
}
EOL

# Create SampleEntity.ts file with specified content
echo "Creating SampleEntity.ts file..."
cat <<EOL > src/application/entities/SampleEntity.ts
// SampleEntity - a sample entity class with a readonly property 'text'
import { ObjectId } from 'mongodb';

export class SampleEntity {
    static Schema = {
        name: "SampleEntity",
        properties: {
            id: 'id',
            text: 'text'
        },
    };
    readonly _id: ObjectId;
    readonly text: string;

    constructor(text: string, id?: ObjectId) {
        this._id = id || new ObjectId();
        this.text = text;
    }
}
EOL


# Create Index.ts file with specified content
# echo "Creating Index.ts file..."
cat <<EOL > src/Index.ts
import 'dotenv/config';

// Importing CLIConfiguration class for handling Command Line Interface (CLI) arguments
import { CLIConfiguration } from "./config/CLIConfiguration";
import { MongoClient } from 'mongodb';
import { Env, dotEnv } from './config/Constants.js';
import { SampleEntityRepository } from './application/repositories/SampleEntityRepository.js';
import { SampleEntity } from './application/entities/SampleEntity.js';

// Extracting command line arguments
const args = process.argv;

// Creating CLIConfiguration object from the extracted CLI arguments
export const configuration: CLIConfiguration = CLIConfiguration.fromCommandLineArguments(args);

// Logging the configuration details
console.log("Application started with environment: " + configuration.env);

(async () => {
    const mongoClient = new MongoClient(configuration.env == Env.Dev ? dotEnv.DEV_MONGO_DB_URL : dotEnv.MONGO_DB_URL)
    const sampleEntityRepository = new SampleEntityRepository(mongoClient);

    await sampleEntityRepository.deleteMany()

    const object1 = new SampleEntity("Hello World!");
    await sampleEntityRepository.insert(object1);

    const objects = await sampleEntityRepository.findAll();
    const firstObject = objects[0];
    await sampleEntityRepository.findOneAndUpdate(firstObject._id, { text: "Hello World! (updated)" });

    const objectAfterUpdate = await sampleEntityRepository.findOne(firstObject._id);
    console.log(objectAfterUpdate?.text);

})();
EOL

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

