import { SampleEntity } from "./SampleEntity";

export class EntityFactory {
    static createSampleEntity(object: any): SampleEntity {
        return new SampleEntity(object.id, object.text)
    }
}
