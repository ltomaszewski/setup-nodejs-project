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
