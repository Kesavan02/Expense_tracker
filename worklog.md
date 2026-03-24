# Expense Tracker Backend Worklog

## Project Inception & Setup
- Initialized a Node.js project for the backend.
- Installed core dependencies: `express`, `mongoose`, `cors`, `helmet`, `morgan`, `dotenv`, `bcrypt`, `jsonwebtoken`.
- Set up the main directory structure:
  - `src/config`: Configuration files (e.g., database connection).
  - `src/controllers`: Request handlers and business logic.
  - `src/middlewares`: Custom middleware (e.g., auth verification).
  - `src/models`: Mongoose database schemas.
  - `src/routes`: API route definitions.
  - `src/utils`: Helper functions (e.g., JWT generation).

## Database Configuration
- Created `src/config/db.js` using Mongoose to connect to the MongoDB instance.
- Verified successful connection to `mongodb://localhost:27017/expense_tracker`.

## Core Application (Express)
- Configured the main entry point `src/index.js`.
- Applied global middleware for security headers (`helmet`), request logging (`morgan`), JSON parsing (`express.json()`), and Cross-Origin Resource Sharing (`cors`).
- Implemented a base `/health` route to verify server status.

## Data Modeling (Mongoose Schemas)
- **User Schema**: Designed to store user details (`name`, `email`, `password`). Includes a pre-save hook to hash passwords using `bcrypt` and a custom method to match passwords during login.
- **Category Schema**: Created to organize transactions. Supports custom categories per user (`userId`), visual markers (`icon`, `color`), and types (`income`/`expense`).
- **Transaction Schema**: Built to track financial records. References `User` and `Category`. Stores `amount`, `type`, `date`, and `description`.
- **Budget Schema**: Created to track spending limits. References `User` and `Category`. Stores `limitAmount`, `startDate`, and `endDate`.

## Authentication API Implementation
- **JWT Generation**: Developed a utility (`src/utils/generateToken.js`) to generate JSON Web Tokens for authenticated sessions.
- **Auth Middleware**: Created `src/middlewares/authMiddleware.js` to extract and verify the JWT from the `Authorization: Bearer <token>` header and attach the user object to incoming requests.
- **Auth Controller**: Implemented logic in `src/controllers/authController.js` for:
  - `registerUser`: Validates input, checks for existing users, created the new user, hashes the password, and returns a token.
  - `loginUser`: Verifies credentials, compares the hashed password, and returns a token.
  - `getMe`: A protected endpoint that returns the currently logged-in user's data.
- **Auth Routes**: Defined route endpoints in `src/routes/authRoutes.js` (`POST /register`, `POST /login`, `GET /me`) and integrated them into the main `index.js` application under the `/api/auth` prefix.

## Documentation Updates
- Updated the `Expense_Tracker_Specification.doc` file.
- Condensend the implementation timeline from a 10-day plan into a 7-day plan, consolidating tasks effectively.
- Standardized the document fonts to `Arial, sans-serif` via an automated script. The modified version is saved alongside the original as `Expense_Tracker_Specification_7_days.doc` due to a file lock on the original document.