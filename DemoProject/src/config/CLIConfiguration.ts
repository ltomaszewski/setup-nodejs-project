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

