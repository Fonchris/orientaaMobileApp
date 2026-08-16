/**
 * Jest config for the integration tests, which run against the Firestore +
 * Storage emulators (see `npm run test:integration`). They are excluded from
 * the default `npm test` run via `testPathIgnorePatterns` in package.json.
 */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/test/integration'],
  // Emulator round-trips (Storage upload/download) are slower than unit
  // tests; give the suite room to breathe.
  testTimeout: 120000,
  maxWorkers: 1,
};
