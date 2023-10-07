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

