// Enumeration representing different environment modes: Development and Production
export enum Env {
    Dev, // Development environment
    Prod // Production environment
}

// Base URL for API endpoints
export const API_BASE_URL: string = "https://api.example.com";

// Maximum number of retries for API requests
export const MAX_RETRIES: number = 3;
// DatabaseHost - the hostname of the RethinkDB server
export const DatabaseHost = '192.168.1.1';
// DatabasePort - the port number of the RethinkDB server
export const DatabasePort = 28015;
// DatabaseForceDrop - indicates whether the database should be forcefully dropped (true/false)
export const DatabaseForceDrop = false;
