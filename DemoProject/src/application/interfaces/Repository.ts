// Repository - Generic Repository type
export type Repository<T> = {
    insert(entity: T): void;
    getAll(): Promise<T[]>
    update(entity: T, newData: Partial<T>): void;
    delete(entity: T): void;
};
