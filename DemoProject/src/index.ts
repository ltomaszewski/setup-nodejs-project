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
