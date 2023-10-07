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

