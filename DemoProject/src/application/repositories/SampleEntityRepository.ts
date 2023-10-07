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
