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

